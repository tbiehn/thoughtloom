Crowd-sourced, open source, and customization-out-front tools continue to make noise in the security tooling marketplace. These are not new developments. We, of course, know about projects like FindBugs and select projects from OWASP. However, new entrants like [Semgrep](https://github.com/returntocorp/semgrep) from [r2c](https://semgrep.dev/) and [Nuclei](https://github.com/projectdiscovery/nuclei) from [ProjectDiscovery](https://projectdiscovery.io/) feel different. What has attracted VC funding to these projects, and what’s behind the excitement and buzz generated from practitioners in the security space? 

To dig in - and perhaps to confirm suspicions - here are the collected results from discussions with old friends who use these tools on a daily basis. These key topics drove those conversations to uncover signal:



* What tools are you using? Why? How do those contrast with incumbent commercial tools?
* What’s the best thing about using them?
* What’s the worst thing?
* What types of issues are they most useful for? Are these pure _defect discovery_? How do they fit into your initiative’s strategy?
* What did you have to build or adopt to make the open sources tools useful?

_Variant analysis_ was an easy idea for industry analysts to latch onto but there’s more to it than that. What makes these tools attractive, in brief, revolves around the advantages of first-class customization support, not cost. Some of the best uses for security tooling aren’t what a vendor’s product people had in mind and the best rules for that tooling can only come from tailoring to the development of real software.

## Core value

The tailorability of rules (and a relatively sparse set of rules/checks that open source tools were shipped with) meant that many of these tools were first marketed as useful to a ‘variant analysis’ capability. This has given way to community efforts to adopt these tools, and private security engineering teams with no commercial interest in _owning_ checker intellectual property have freely turned them over to improve everyone’s experience of using these tools. Security and engineering groups also encourage the adoption of open or in-house risk-eliminating practices like using secure-by-default architectures. And finally, due to their flexibility, these tools are useful outside of their apparent remit of finding problems in software.

Variant analysis is the elimination of a type of defect across a set of software - variant analysis usually means you’ve identified a single expression of a problem, and can generalize a check or rule for that expression across that population. An accessible example of variant analysis for Semgrep is;



1. _FooBar Bank_’s login page suffered from SQL injection, the expression is the dataflow & lines of code responsible, 
2. A pattern is identified; information in GET parameters reaching a string used as a SQL query, and
3. Semgrep is used to look for that pattern across all the Java code at _FooBar Bank_.

And a similar example for Nuclei;



1. DNS servers are compromised with guessed credentials.
2. A pattern is identified; _FooBar Bank’s_ outsourced DNS experts keep setting up servers with the administrative password `BigFour123!`,
3. Nuclei is used to look for SSH servers that have `root`/`BigFour123!` across _FooBar Bank_ infrastructure. (Or those lacking MFA, or privileged access management, or …)

Closely related to a variant analysis use-case is the example of sharing rules for error-prone parts of platforms or frameworks, the formats of Nuclei templates or Semgrep rules are starting to become dominant in the open exchange of ideas between industry professionals. Similar to the distribution of YARA rules by the infrastructure security set, the fast community prototyping and evaluation of Semgrep rules for the reachability of a new CVE or defect type is gaining ground. Participating in this ecosystem means you’re better able to run with the herd.

{{<bc "Edsger W. Dijkstra">}}
...complexity sells better.
{{</bc>}}

You used to have to beg for a vendor to support finding a particular CVE, or wait for someone else to figure out the combinations of sources, sinks, and mistakes across the particular set of libraries and frameworks used by your different development teams, or deal with arcane rule languages, but now you can do this in house in reaction to bug bounties, penetration testing reports, or in-house threat modeling and development stack assessments. Increasingly these teams who work closely with real developers and real code are open sourcing the checks they create in-house, putting open source tooling more and more in direct competition with market incumbents. Anshuman mentioned that his team puts Nuclei templates into their bug bounty response process, in one case forking an existing rule in response to a bug bounty report and tailoring it to his organization’s code-bases. With that rule in place their automated tooling is able to pick up variants or regressions into the future.

These tools are also enabling one of the highest return security activities: using secure-by-default architectural components. Secure-by-default eliminates problems, and eliminated problems don’t need to be looked for, accounted for, or managed-to-remediation - yet secure-by-default remains relatively rare. Using open source tools solves a tricky element of encouraging component adoption - they can be used to detect when developers have failed to use secure-by-default approaches, and then used to nudge those teams back towards safer pastures with whatever incentives and disincentives work best for your organization. For example, maybe you want development teams to eliminate the risk of cross-site-scripting vulnerabilities by using HTML templates instead of writing raw HTML responses in _golang_. Semgrep might be used to look for instances where `http.ResponseWriter` is not being used by `template.Execute`, and then you can trigger an array of things, such as dropping the developer a slack message about how cool HTML templates are, flagging a particular build for more stringent XSS checks and security delays, or just marking a particular project as more error-prone. Tim shared an example where his developers were working on an authentication and authorization package, as they developed their secure-by-default library, they began introducing Semgrep rules that gradually removed access to functionality this library provided. Anshuman shared that as good as it is to have secure-by-default frameworks, getting developers to use them is another issue, his tooling is able to nudge developers towards safe-by-default frameworks when a push to a repository happens.

Most interesting are unanticipated use cases - security tools commonly emit artifacts, have intermediate results, or have technical capabilities that could be leveraged for reasoning about populations of code and coders, if only they were unlocked. Open source tools don’t have these limitations - Semgrep and Nuclei can be used for portfolio level efforts to understand code, coding practices, and coding risk in ways that can drive interesting and effective behavior by security teams. One typical use case is software inventory and risk analysis - sure you can ask a development team if their project uses, for example, _credit card services_, but with Semgrep you can just write a query for them. With a set of checks that tell you what software properties express risk, you can realize many benefits of threat modeling in a totally automated way - use that information to automatically risk-score applications in your inventory, and respond with automation to address risk. Nuclei can similarly be used along with its Wappalyzer set to determine, experimentally, attacker-facing application stacks, which is a useful list to have when deciding what an initiative could focus on next.

One potential of these tools is teased by Alphabet’s [Tricorders](https://research.google/pubs/pub43322/) project, an effort to replace big-box static analysis tools with a largely in-house pipeline. One interesting observation was that engineers who were contributing to libraries or frameworks had begun writing and distributing their own checks and rules to enforce safe use of their APIs. Those engineers in some cases even simplified APIs to make issues easier for tooling to catch. Instead of incorporating pitfalls in documentation that developers need to read or memorize, guidance can be provided as code. Those engineers gain more agency over the safety or error-prone-ness of their own code, and seem to want to make that code less risky to build on. Tim’s firm has a solid infusion of ex-Google folks, and unsurprisingly, those engineering teams are already writing their own Semgrep checks, and his infrastructure folks incorporate automated Nuclei checks to enforce their own standards. Open source projects with simple rule languages like Nuclei and Semgrep are in a great position to become the _lingua franca_ used by modern engineers and distributed alongside popular development frameworks to realize similar dynamics outside of the halls of super-high-tech-firms.


## Operation

Starting with these tools doesn’t take much more than pulling copies down and running them against raw targets. Those squeezing good value from these tools all had to develop a few capabilities we can learn from:

* Automated Execution - Tools can be instantiated ad-hoc, or by automation as part of normal or scheduled processes. You can throw them in containers and run them with docker.
* Centralized Rules - Rules can come from anywhere, and new instances of the tools use the latest rules from the set. You can keep your rules in a Git repo, and put them into your automated container builds.
* Environmental Integration - Tool conditions can reach affected parties natively. Asynchronous Semgrep insights wind up as bot-contributed comments on pull-requests.
* Environmental Feedback - Impacted populations can complain about results. For example, you collect ‘not-useful’ information from bot comments, and act on that when over ten percent of flagged issues come back as not-useful for a given rule.

These capability areas have their own levels of maturity, and reflect predominant and established use-cases. They’re ‘table stakes’ before getting into nascent capabilities like automated inventory risk assessment; it probably means mashing tool output up with inventory and pursuing further integrations with governance as code elements.


## Insights

These tools can scale an individual bit of knowledge trapped inside a security engineer across a portfolio of code, or the world’s code. Their flexibility means you can count on these tools to tell you more about your software, rather than if that software just has a particular security problem.

Realizing secure by default, automated inventory, risk assessments, and threat modeling, means developing patterns and seeing what systems of incentives work best with different engineering populations. It’s a lot of work for any one organization - you’ll want to establish and cultivate ways of effectively collaborating in the commons on building these datasets.

Community sourced checks and rules are one way to keep pace with the growth of platform, library, framework, and development paradigms. Investors have started to realize the dynamics of addressing checker and rule-set scale with closed source business models that lack credible network effects, the advantages of last-mile customizability, and the advantages of letting skilled customers that are also engineers take the products to interesting and unanticipated places.

Everyone involved with security has run into burnout caused by a mismatch of commercial security tools with development practice, massive run-times because they need to reduce false positive rate in the face of outrageously risky programming practices, traps of point-solution driven penetrate and patch behavior, and those tools' inflexibility to address those problems yourself. Give yourself, your initiative, and your community of security engineers the ability to overcome these problems by investing in, becoming familiar with, and leveraging these promising open source tools.

{{<bc "Alan Kay">}}
The best way to predict the future is to invent it.
{{</bc>}}

## Acknowledgements

I’ve long been curious about how the dynamics of open source tooling have been playing out in industry, and without the illuminating conversations I’ve had with old colleagues this article would not exist.



* [Anshuman Bhartiya](https://www.anshumanbhartiya.com/), AppSec specialist at a California tech firm, a history of Fortune 500 and startup experience. 
* [Ty Bross](https://twitter.com/AnInsiderThreat), AppSec and CloudSec specialist.
* [Parsia Hakimian](https://parsiya.net/), AppSec specialist, static analysis enthusiast, and avid gamer.
* [Tim Michaud](https://twitter.com/TimGMichaud), AppSec with a Machine Learning startup.
* Plus one participant who wished to remain anonymous, focused on automated/scaled infrastructure security at a Fortune 500 tech company.

Thanks to [Sammy Migues](https://www.linkedin.com/in/sammymigues/) and [Mike Doyle](https://twitter.com/Fe3Mike) who provided extensive feedback and edits.