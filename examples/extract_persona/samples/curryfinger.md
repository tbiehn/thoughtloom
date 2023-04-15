`CURRYFINGER` measures a vanilla request for a particular URL against requests directed to specific IP addresses with forced TLS SNI and HTTP Host headers. The tool takes a string edit distance, and emits matches according to a rough similarity metric threshold.

There are many guides that explain the process of finding servers that may actually host a CDN fronted domain, which all boil down to;

 * Plug the domain name into `$OSINTTool`; shodan, censys, etc.
 * Collect IP addresses.
 * ????
 * Profit

## Motivation

"But Travis," you say "we already have a tool for this, why do we need yet another one?"

Many guides point to an open source tool, [christophetd/CloudFlair](https://github.com/christophetd/CloudFlair), that roughly does this;

 * Downloads CloudFlare's IP ranges.
 * Checks whether a supplied domain resolves to an IP within those ranges.
 * Queries the Censys API for IPs serving X.509 certificates with the provided domain in the `CN=` (CommonName) attribute.
 * Loads each IP, and compares the result against a control.

Unfortunately, `cloudflair.py` is a little slow, and it fails to indentify true-positives in many cases. Concretely, downloading CloudFlare's IP lists on every run compounds already slow `python` warm-up times - and, maybe more importantly, `cloudflair.py` will not work on non-CloudFlair CDNs.

Why not just commit to an existing project? One; Python has its uses, but writing highly performant multi-threaded scanners is not one of them. Two; we get value from separating the concerns of identifying targets and verifying them, to try other, more egregious methods at finding candidate origin servers than commercial OSINT platforms.

`CURRYFINGER` demonstrates the kind of effective PoC you can pump out in a few hours using Golang. It has been battle tested against thousands of domains, across hundreds of thousands of requests, and run on dozens of servers. I'll share that information in another post, but let's just take a look at one example;

## Head 2 Head & Demo

Here, we put `cloudflair.py` up against `CURRYFINGER` in an attempt to identify the real server behind the popular "chat" website `chaturbate.com`. 

### Left Pane - CloudFlair
We launch `./cloudflair.py -o chatbate.txt chaturbate.com` - kicking off the process of finding targets and carrying out similarity analysis. 

### Right Pane - CURRYFINGER

We find targets by querying the Shodan REST API; `curl "https://api.shodan.io/shodan/host/search?key=$SHO&query=ssl%3A\"chaturbate.com\"" | jq ".matches|.[].ip_str" | tr -d "\"\t " | tee chaturbate.com.txt` 

{{<aside>}}
 the `jq` command selects only ip addresses from the response, and `tr` trims up quotes and whitespace. You can easily substitute Censys or a list of `masscan -p443`'d hosts here.
{{</aside>}}

Then we invoke `CURRYFINGER` on the results to find which IPs seem like the real origin servers behind the CDN; `./CURRYFINGER -file chaturbate.com.txt -show=false -url https://chaturbate.com 2>/dev/null | tee res.txt`

Then we drop the CloudFlare IP addresses from the results; `grep ^match res.txt | grep -v 104.16|cut -d " " -f 2`

We finally manually examine the full response by forcing `curl` to resolve a domain with a specific IP; `curl -vik --resolve chaturbate.com:443:$IP https://chaturbate.com`

### Destruction

{{<aside>}}Full screen this to see the carnage.{{</aside>}}

{{<asciinema "267327" >}}

### So What

**tl;dr**; `cloudflair.py` is still running after `CURRYFINGER` completes and we've verified the results. By the time `cloudflair.py` finishes, it has failed to identify the correct server, even though _Censys found the IP, and `cloudflair.py` checked it._

{{<aside>}}Reducing `CURRYFINGER`'s timeout with `-timeout 1s` results in a, perhaps a too effective, trounce.{{</aside>}}

### Getting IP Addresses
If you have a free Shodan account, you have an API Key;

{{<code "Grab some IPs">}}
{{<highlight sh>}}
export SHO=[YOUR SHODAN API KEY]
export DOMAIN=example.com
curl "https://api.shodan.io/shodan/host/search?key=$SHO&query=ssl%3A\"$DOMAIN\"" | jq ".matches|.[].ip_str" | tr -d "\"\t " | tee targetIPs.com.txt
{{</highlight>}}
{{</code>}}

You can also grab CIDR ranges for popular cloud hosting providers, and `masscan -p443` them. I'll explore this option in another article.


### Ulimits

`CURRYFINGER` does full connects, and doesn't know what your `ulimit`s are. So, juice those up before a run; `ulimit -n 60000`. Yep.


### VHOST check; lots of domains, just a few IPs

With a pile of IP addresses in `targetIPs.com.txt` and a pile of domains in `targetDOMAINS.txt` you can quickly test for the presence of every domain on every IP by using GNU `parallel`.

{{<code "Vanilla application of GNU Parallel">}}
{{<highlight bash>}}
parallel -j 20 ./CURRYFINGER -url https://{} -threads 200 -show=false -timeout 3s -file targetIPs.com.txt :::: targetDOMAINS.txt 2>/dev/null | grep ^match | tee results.txt
{{</highlight>}}
{{</code>}}

### All together now; match subdomains
Pull subdomains for a target domain before running `CURRYFINGER` now you're cooking with concentrated freedom. Of course, use whatever tools you want, `amass`, `subbrute`, Censys, Shodan, `masscan`, whatever.

{{<code "Set up env vars.">}}
{{<highlight sh>}}
export SHO=[YOUR SHODAN API KEY]
export DOMAIN=example.com
{{</highlight>}}
{{</code>}}

Here's what that looks like using `turbolist3r.py`; 

{{<code "Grab subdomains">}}
{{<highlight sh>}}
python turbolist3r.py -e ssl,ask,bing,google,yahoo,netcraft,dnsdumpster,virustotal,threatcrowd,passivedns -d $DOMAIN -o targetDOMAINS.win.txt

##Fix newlines...
cat targetDOMAINS.win.txt | tr -d "\r"  >> targetDOMAINS.txt
echo $DOMAIN>>targetDOMAINS.txt
{{</highlight>}}
{{</code>}}

{{<code "Let it rip with 400 parallel instances of CURRYFINGER and match against more bytes.">}}
{{<highlight bash>}}
curl "https://api.shodan.io/shodan/host/search?key=$SHO&query=ssl%3A\"$DOMAIN\"" | jq ".matches|.[].ip_str" | tr -d "\"\t " | tee targetIPs.com.txt

ulimit -n 60000

parallel -j 400 ./CURRYFINGER -url https://{} -threads 200 -show=false -timeout 3s -mbits 5000 -file targetIPs.com.txt :::: targetDOMAINS.txt 2>/dev/null | grep ^match | tee results.txt
{{</highlight>}}
{{</code>}}

## Grab your own copy

From [https://github.com/tbiehn/CURRYFINGER.](https://github.com/tbiehn/CURRYFINGER)
