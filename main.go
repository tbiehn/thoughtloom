package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"

	"golang.org/x/text/unicode/norm"

	"github.com/pkoukk/tiktoken-go"
	"github.com/sirupsen/logrus"
	"github.com/vbauerster/mpb/v8"

	"github.com/BurntSushi/toml"
	"github.com/cenkalti/backoff/v4"
	openai "github.com/sashabaranov/go-openai"
	gptparallel "github.com/tbiehn/gptparallel"
)

type CommandLineFlags struct {
	configPath     string
	dryRun         bool
	logLevel       string
	disableBar     bool
	concurrency    int
	azureEndpoint  string
	azureModelName string
}

var log = logrus.New()
var tripleQuotePattern = regexp.MustCompile(`(?m)^"{3}$`)

func setupLogger(logLevel string) {
	// Set log output to stderr and set the log level
	log.Out = os.Stderr

	level, err := logrus.ParseLevel(logLevel)
	if err != nil {
		log.Fatalf("Invalid log level: %v", err)
	}

	log.SetLevel(level)

	// Customize log format
	log.SetFormatter(&logrus.TextFormatter{})
}

type Config struct {
	SystemPromptFile string             `toml:"template_system"`
	UserPromptFile   string             `toml:"template_user,omitempty"`
	PromptFiles      []PromptFileConfig `toml:"template_prompt,omitempty"`
	Model            string             `toml:"model"`
	MaxTokens        int                `toml:"max_tokens"`
	Temperature      *float32           `toml:"temperature,omitempty"`
	TopP             *float32           `toml:"top_p,omitempty"`
	PresencePenalty  *float32           `toml:"presence_penalty,omitempty"`
	FrequencyPenalty *float32           `toml:"frequency_penalty,omitempty"`
}
type PromptFileConfig struct {
	Role     string `toml:"role"`
	Template string `toml:"template"`
}

func LoadConfig(configPath string) (Config, error) {
	var config Config
	if _, err := toml.DecodeFile(configPath, &config); err != nil {
		return Config{}, err
	}
	return config, nil
}

func LoadTemplate(templatePath string) (*template.Template, error) {
	return template.ParseFiles(templatePath)
}

func processJSONInput(flags CommandLineFlags, jsonInput string, requestsChan chan<- gptparallel.RequestWithCallback) {
	// Load the configuration
	config, err := LoadConfig(flags.configPath)
	if err != nil {
		log.Fatalf("Failed to load config: %v\n", err)
		return
	}

	// Get the base directory of the configPath
	configDir := filepath.Dir(flags.configPath)

	// Load the system and user templates with paths relative to configPath
	systemTemplate, err := LoadTemplate(filepath.Join(configDir, config.SystemPromptFile))
	if err != nil {
		log.Fatalf("Failed to load system template: %v\n", err)
		return
	}

	// Parse the JSON input
	var jsonData map[string]interface{}
	if err := json.Unmarshal([]byte(jsonInput), &jsonData); err != nil {
		log.Fatalf("Failed to parse JSON: %v\n", err)
		return
	}

	systemPrompt, err := RenderTemplate(systemTemplate, jsonData)
	if err != nil {
		log.Fatalf("Failed to render system template: %v\n", err)
		return
	}

	request := openai.ChatCompletionRequest{
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: systemPrompt,
			},
		},
		Model:     config.Model,
		MaxTokens: config.MaxTokens,
	}

	// Handle old-style configuration
	if config.UserPromptFile != "" {
		userTemplate, err := LoadTemplate(filepath.Join(configDir, config.UserPromptFile))
		if err != nil {
			log.Fatalf("Failed to load user template: %v\n", err)
			return
		}
		userPrompt, err := RenderTemplate(userTemplate, jsonData)
		if err != nil {
			log.Fatalf("Failed to render user template: %v\n", err)
			return
		}

		chatMessages := append(request.Messages,
			openai.ChatCompletionMessage{
				Role:    openai.ChatMessageRoleUser,
				Content: string(userPrompt),
			},
		)
		request.Messages = chatMessages
	}

	// Handle new-style configuration
	for _, promptFileConfig := range config.PromptFiles {
		role := openai.ChatMessageRoleUser

		switch strings.ToLower(promptFileConfig.Role) {
		case "user":
			role = openai.ChatMessageRoleUser
			break
		case "assistant":
			role = openai.ChatMessageRoleAssistant
			break
		default:
			log.Fatalf("Invalid role in TOML configuration")
		}

		msgTemplate, err := LoadTemplate(filepath.Join(configDir, promptFileConfig.Template))
		if err != nil {
			log.Fatalf("Failed to load message template: %v\n", err)
			return
		}

		message, err := RenderTemplate(msgTemplate, jsonData)
		if err != nil {
			log.Fatalf("Failed to render message template: %v\n", err)
			return
		}

		chatMessages := append(request.Messages, openai.ChatCompletionMessage{
			Role:    role,
			Content: string(message),
		})
		request.Messages = chatMessages

	}

	if config.Temperature != nil {
		request.Temperature = *config.Temperature
	}
	if config.TopP != nil {
		request.TopP = *config.TopP
	}
	if config.PresencePenalty != nil {
		request.PresencePenalty = *config.PresencePenalty
	}
	if config.FrequencyPenalty != nil {
		request.FrequencyPenalty = *config.FrequencyPenalty
	}

	requestsChan <- gptparallel.RequestWithCallback{
		Request: request,
		Callback: func(result gptparallel.RequestResult) {
			//We're not worried about doing anything here.
		},
		Identifier: jsonInput,
	}
}

func banner() {
	text := `ThoughtLoom: Unlock the Power of LLMs
Reads JSON objects from stdin, processes them using templates, connects to OpenAI (or Azure) APIs, and emits JSON responses.

Usage:
1. Supply input JSON through stdin.
2. Set your OpenAI API key using the 'OPENAI_API_KEY' environment variable, or Azure AI API key using 'AZUREAI_API_KEY' environment variable.

WARNING: API requests may incur costs. Use the flag '-d' to estimate your potential cost before running the actual process.
`

	_, _ = fmt.Fprintln(os.Stderr, text)
}
func main() {
	banner()

	var flags CommandLineFlags
	flag.StringVar(&flags.configPath, "c", "./config.toml", "c[onfig] Path to configuration file")
	flag.BoolVar(&flags.dryRun, "d", false, "d[ry] Perform a dry run, calculating token usage without making a request. Set -d all by itself to enable it.")
	flag.StringVar(&flags.logLevel, "l", "info", "l[og] level (options: debug, info, warn, error, fatal, panic)")      // Keep this flag for log level
	flag.BoolVar(&flags.disableBar, "b", false, "b[ar] Disable the progress bar. Set -b all by itself to disable it.") // Keep this flag to disable the progress bar
	flag.IntVar(&flags.concurrency, "p", 5, "p[arallel] How many parallel calls to make to OpenAI.")
	flag.StringVar(&flags.azureEndpoint, "ae", "", "a[zure]e[ndpoint] Set if using Azure. Your OpenAI HTTP Endpoint. Set environment variable 'AZUREAI_API_KEY' to your API key.")
	flag.StringVar(&flags.azureModelName, "am", "", "a[zure]m[odel] Set if using Azure. Your model deployment name.")

	flag.Parse()

	setupLogger(flags.logLevel)

	var client *openai.Client

	if flags.azureEndpoint != "" {
		if flags.azureModelName == "" {
			log.Fatalf("An Azure model name must be provided when using Azure endpoint.")
		}

		azureAPIKey := os.Getenv("AZUREAI_API_KEY")
		if azureAPIKey == "" {
			log.Fatalf("AZUREAI_API_KEY environment variable not set")
		}

		config := openai.DefaultAzureConfig(azureAPIKey, flags.azureEndpoint, flags.azureModelName)
		client = openai.NewClientWithConfig(config)
	} else {
		openAIKey := os.Getenv("OPENAI_API_KEY")
		if openAIKey == "" {
			log.Fatalf("OPENAI_API_KEY environment variable not set")
		}

		client = openai.NewClient(os.Getenv("OPENAI_API_KEY"))
	}

	ctx := context.Background()
	backoffSettings := backoff.NewExponentialBackOff()

	bar := mpb.New(mpb.WithOutput(log.Out)) // Keep this line to redirect the mpb output to stderr

	var g *gptparallel.GPTParallel
	var gptResultsChan <-chan gptparallel.RequestResult

	if flags.disableBar {
		bar = nil // Set to nil if the progress bar is disabled
	}

	requestsChan := make(chan gptparallel.RequestWithCallback)

	if flags.dryRun {
		gptResultsChan = make(chan gptparallel.RequestResult)
	} else {
		g = gptparallel.NewGPTParallel(ctx, client, bar, backoffSettings, log)
		gptResultsChan = g.RunRequestsChan(requestsChan, flags.concurrency)
	}

	go func() {
		for jsonInput := range ReadJSONStream(os.Stdin) {
			processJSONInput(flags, jsonInput, requestsChan)
		}
		close(requestsChan)
	}()

	tokenCosts := map[string]struct {
		ContextTokensCost    float64
		CompletionTokensCost float64
	}{
		"gpt-4": {
			ContextTokensCost:    0.03,
			CompletionTokensCost: 0.06,
		},
		"gpt-4-32k": {
			ContextTokensCost:    0.06,
			CompletionTokensCost: 0.12,
		},
		"gpt-3.5-turbo": {
			ContextTokensCost:    0.002,
			CompletionTokensCost: 0.002,
		},
	}

	if flags.dryRun {
		totalTokens := 0
		outputTokens := 0
		totalTokenCost := float64(0)
		outputTokensCost := float64(0)
		fmt.Fprintln(os.Stderr, "\n\nSubmissions:")
		for output := range requestsChan {
			fmt.Fprintf(os.Stderr, "%+v\n", output.Request)
			num, err := numTokensFromMessages(output.Request)
			if err != nil {
				log.Fatalf("Error calculating total tokens %v", err)
			}
			totalTokens += num
			outputTokens += output.Request.MaxTokens

			costModel, ok := tokenCosts[output.Request.Model]
			if ok {
				totalTokenCost += float64(num) / 1000 * costModel.ContextTokensCost
				outputTokensCost += float64(output.Request.MaxTokens) / 1000 * costModel.CompletionTokensCost
			}

		}
		fmt.Printf("Input/context %d, Maximum Output %d, Combined: %d\n", totalTokens, outputTokens, totalTokens+outputTokens)
		fmt.Printf("Estimated cost - Context: $%.4f, Completion: $%.4f, Worst-Case Total: $%.4f\n", totalTokenCost, outputTokensCost, totalTokenCost+outputTokensCost)

		return
	}
	for output := range gptResultsChan {
		log.Debug("Processing a gptResultsChan")
		outputBytes, err := json.Marshal(output)
		if err != nil {
			log.Errorf("Couldn't marshall response %s", err)
			panic(1)
		}
		fmt.Println(string(outputBytes))
	}
}

func ReadJSONStream(r io.Reader) chan string {
	decoder := json.NewDecoder(r)
	jsonInputs := make(chan string)

	go func() {
		defer close(jsonInputs)

		for {
			var jsonObject map[string]interface{}
			err := decoder.Decode(&jsonObject)

			if err == io.EOF {
				break
			}

			if err != nil {
				log.Errorf("Failed to parse JSON: %v", err)
				continue
			}

			jsonStr, err := json.Marshal(jsonObject)
			if err != nil {
				log.Errorf("Failed to convert JSON back to string: %v", err)
				continue
			}

			jsonInputs <- string(jsonStr)
		}
	}()

	return jsonInputs
}

// Turn three double quotes on a line to... four quotes on a line. """"
// This is pretty sus.
func SanitizeForModel(s string) string {
	//Normalize to NFKC for maximum model deliciousness. Sorry strange inputs.
	s = norm.NFKC.String(s)
	//Trim spaces.
	s = strings.TrimSpace(s)
	//Escape triple quotes.
	return tripleQuotePattern.ReplaceAllString(s, `""""`)
}

// autoSanitize NKFC's, strims out spaces, and """->"""" 's for all the inputs.
func autoSanitize(data interface{}) interface{} {
	switch v := data.(type) {
	case string:
		return SanitizeForModel(v)
	case []interface{}:
		for i, elem := range v {
			v[i] = autoSanitize(elem)
		}
	case map[string]interface{}:
		for key, value := range v {
			v[key] = autoSanitize(value)
		}
	}
	return data
}

// RenderTemplate renders the template with the given data.
func RenderTemplate(tmpl *template.Template, data interface{}) (string, error) {
	var buf bytes.Buffer
	sanitizedData := autoSanitize(data)
	if err := tmpl.Execute(&buf, sanitizedData); err != nil {
		return "", err
	}
	return buf.String(), nil
}

//Lifted from https://github.com/openai/openai-cookbook/blob/main/examples/How_to_count_tokens_with_tiktoken.ipynb

func numTokensFromMessages(request openai.ChatCompletionRequest) (int, error) {
	model := request.Model
	if strings.HasPrefix(model, "gpt-4") {
		model = openai.GPT4
	} else if strings.HasPrefix(model, "gpt-3.5-turbo") {
		model = openai.GPT3Dot5Turbo
	}

	messages := request.Messages

	encoding, err := tiktoken.EncodingForModel(model)
	if err != nil {
		return 0, err
	}

	tokensPerMessage := 4
	tokensPerName := -1

	if model == openai.GPT3Dot5Turbo {
		tokensPerMessage = 4
		tokensPerName = -1
	} else if model == openai.GPT4 {
		tokensPerMessage = 3
		tokensPerName = 1
	} else {
		return 0, fmt.Errorf("num_tokens_from_messages() is not implemented for model %s. See https://github.com/openai/openai-python/blob/main/chatml.md for information on how messages are converted to tokens.", model)
	}

	numTokens := 0
	for _, message := range messages {
		numTokens += tokensPerMessage
		numTokens += len(encoding.Encode(string(message.Role), nil, nil))
		numTokens += len(encoding.Encode(message.Content, nil, nil))
		if message.Name != "" {
			numTokens += len(encoding.Encode(message.Name, nil, nil)) + tokensPerName
		}
	}
	numTokens += 3 // every reply is primed with assistant

	return numTokens, nil
}
