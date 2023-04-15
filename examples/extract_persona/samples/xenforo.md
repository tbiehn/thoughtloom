TL;DR - You can skip right to the [results]({{< relref "#results" >}}) for the code.

A list that recently hit [Hashes.org](http://hashes.org), with 1 million records and a low crack rate, looked like an interesting target, given that the community had recovered less than 0.5% of the list. On taking a closer look, we find out why;

Out of the box, only John the Ripper (JtR) Jumbo carries support for the XenForo hash scheme[^1] as a **dynamic hash**[^2].

[^2]: https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/DYNAMIC
[^1]: https://github.com/magnumripper/JohnTheRipper/blob/323f4babdefadfae99568474557dacc2a130d8b3/run/dynamic.conf#L945


JtR’s dynamic hashes don’t run on OpenCL, and a benchmark on a single core resulted in 4MH/s, while during a run we hit around 80MH/s across 20 CPU Cores. (H/T Solar Designer for the correction.)

{{<img "jtrimg" "Around 4 MH/s from JtR in CPU mode." >}}

What we had was a pretense for writing a custom OpenCL kernel for Hashcat—perfect. Adding to the effort was the lack of documentation around Hashcat (and sparse code comments).

My general methodology was running Hashcat in single-hash mode against the kernel and using `printf()` debugging statements to understand what was going on under the hood. Hashcat's other kernels and its OpenSSL-style functions were definitely key to getting something working in a limited amount of time.

{{<aside>}}Compared to C on *nix, OpenCL development is exotic. If you have a solid environment for Hashcat work, let me know.
{{</aside>}}

## Orientation

`./hashcat/include/interface.h`[^3]
: `enums` and values required to add a new hash type.

`./hashcat/src/interface.c`[^4]
: Blocks that describe each hash type. It contains strings for Hashcat’s help function, as well as various constants and hash-parsing functions.

`./hashcat/kernels/`
: Compiled OpenCL kernels. Hashcat compiles each OpenCL kernel at runtime and caches those kernels here.

`./hashcat/OpenCL/`[^5]
: OpenCL kernel sources (`.cl` files).

[^3]: https://github.com/hashcat/hashcat/blob/master/include/interface.h
[^4]: https://github.com/hashcat/hashcat/blob/master/src/interface.c
[^5]: https://github.com/hashcat/hashcat/tree/master/OpenCL

## Play-by-play

{{<bc "Dr. Conrad Zimsky (Stanley Tucci), The Core (2003)">}}
let me smoke a cigarette, and I'll tell you.
{{</bc>}}

### Inspiration
To start with, we identify an OpenCL `a0` kernel (or set of kernels) that closely matches our workload and input type. For example, if your hash is salted, find a salted hash of the same type, and likewise if it is iterated.

Copy it to its own kernel file, designated as `m[Hashcat Mode Flag]_a0-pure.cl`. Search/replace this source to fix up the mode function names. In this guide, I used `m01410_a0-pure.cl`[^m01410_a0-pure] as the donor kernel. I'll be using `m01415_a0-pure.cl` for the new mode `1415`.
[^m01410_a0-pure]: https://github.com/hashcat/hashcat/blob/master/OpenCL/m01410_a0-pure.cl

{{<aside wide>}}Hashcat follows a loose naming convention for modes: `xxxyy`, where `xxx` denotes the family and `yy` is either `00` for unsalted, `10` for an appended salt, or `20` for a prepended salt. There are plenty of counter-examples, but this is the general scheme.{{</aside>}}

### Adding the mode

Next up, add the new mode to Hashcat.

We add a new `enum` value `SHA256_PW_SHA256_SLT` to `interface.h` and set it equal to `1415`:

{{<code "Grabbing a new Hashcat `-m`ode flag, `1415`, for the XenForo mode." >}}
	{{<highlight c>}}
KERN_TYPE_SHA256_PWSLT = 1410,
KERN_TYPE_SHA256_PW_SHA256_SLT = 1415,
KERN_TYPE_SHA256_SLTPW = 1420,
{{</highlight>}}
{{</code>}} 

`HT_`* is CLI / Help-related Text and a new entry `HT_01415` is added to `interface.c`:

{{<code "Adding reference to our new XenForo mode in `interface.c`." >}}
	{{<highlight c>}}
case 1411: return HT_01411;
case 1415: return HT_01415;
case 1420: return HT_01420;
static const char *HT_01410 = "sha256($pass.$salt)";
static const char *HT_01415 = "sha256(sha256($pass).$salt)";
static const char *HT_01420 = "sha256($salt.$pass)";
{{</highlight>}}
{{</code>}} 

A test hash `ST_HASH_01415` plus its corresponding plaintext `ST_PASS_HASHCAT_PEANUT` are used for self-testing:

{{<code "Adding a test hash and plaintext to `interface.c`." >}}
	{{<highlight c>}}
static const char *ST_PASS_HASHCAT_PEANUT = "peanut";
…
static const char *ST_HASH_01415 = "00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa:b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449";
…
case 1411: hashconfig->hash_type = HASH_TYPE_SHA256;
{{</highlight>}}
{{</code>}} 

And in the main hash configuration block, the values were lifted from `case 1410:`, `sha256($plain.$salt)`.

An important bit here is to set `kern_type` to the `enum` added to `interface.h`, in this case `KERN_TYPE_SHA256_PW_SHA256_SLT`. `parse_func` is a function pointer, set to `sha256s_parse_hash` - which will be invoked to parse the hash list. If your hash format can't be consumed by these functions exactly, it will be rejected. Hashcat has a robust set of these parsing functions, and you'll want to hunt through them in `interface.c`[^hcparse].  
[^hcparse]: https://github.com/hashcat/hashcat/blob/dbbba1fbdf05403675ddbf7d3b36f42ab7b76f68/include/interface.h#L1509

{{<aside>}}`opti_type` does *something*. Reach out if you have some information about its semantics, and I'll update this article.{{</aside>}}


### Quick and dirty test

After a `make clean && make`, Hashcat should list your new type. Benchmark mode won't be useful for testing, as the `a0` kernels aren’t used here. Running a simple single-hash test against the new kernel will cause Hashcat to build it from the `OpenCL` directory to the `kernels` directory. This is when you'll receive compile-time errors. 
{{<aside>}}There's probably a way to directly invoke the OpenCL build toolchain to speed this up. Let me know if you know.{{</aside>}}

In this case, I had known hash/salt/plaintext values (recoverable from JtR and publicly listed). These are essential. You'll find out how to use the raw results of intermediate steps in the scheme for debugging in the next section.

I used this example for testing:

{{<code "Sample XenForo hash, salt, and plaintext tuple - for the plaintext 'peanut'. The format is `[hash]:[salt]:[plaintext]`.">}}
{{<highlight text>}}
00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa:b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449:peanut
{{</highlight>}}
{{</code>}}

Steps from the command line:

{{<code "Re-create the sample hash for 'peanut' using `shasum`. This confirms our scheme.">}}
{{<highlight text>}}
## echo -n peanut | shasum -a 256
5509840d0873adb0405588821197a8634501293486c601ca51e14063abe25d06 –
## echo -n 5509840d0873adb0405588821197a8634501293486c601ca51e14063abe25d06b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449 | shasum -a 256
00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa –
{{</highlight>}}
{{</code>}}

{{<rag>}}
Reviewing; with the `$salt` value `b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449` where `sha256('peanut')` is `5509840d0873adb0405588821197a8634501293486c601ca51e14063abe25d06` and `sha256(sha256('peanut') . $salt)` is `00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa`. As expected by `sha256(sha256($pass).$salt)`.
{{</rag>}}

Hashcat test:

{{<code "Testing our new `-m`ode 1415's `-a 0` kernel. `peanut.txt` contains the word 'peanut'.">}}
{{<highlight text>}}
## ./hashcat -m 1415 -a 0 “00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa:b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449” peanut.txt

hashcat (v4.0.1-123-g2095e27d+) starting…
OpenCL Platform #1: Apple

=========================

* Device #1: Intel(R) Core(TM) i7-6920HQ CPU @ 2.90GHz, skipped.
* Device #2: Intel(R) HD Graphics 530, 384/1536 MB allocatable, 24MCU
* Device #3: AMD Radeon Pro 460 Compute Engine, 1024/4096 MB allocatable, 16MCU

…
Watchdog: Temperature abort trigger disabled.
* Device #2: ATTENTION! OpenCL kernel self-test failed.
Your device driver installation is probably broken.

See also: https://hashcat.net/faq/wrongdriver
* Device #3: ATTENTION! OpenCL kernel self-test failed.
Your device driver installation is probably broken.

See also: https://hashcat.net/faq/wrongdriver
{{</highlight>}}
{{</code>}}

We now have a custom Hashcat build that lists our new type. Awesome. Let’s get these self-tests to pass with a single hash.

### Kicking out the jams

{{<bc "MC5, Kick Out the Jams (1969)">}}
You gotta have it, baby, you can't do without

Oh, when you get that feeling you gotta sock 'em out
{{</bc>}}

The majority of the work on an `a0` kernel will be focused on these two functions:

{{<aside>}}We're using the donor kernel `m01410`, and we've renamed all the `1410`'s to `1415`'s. {{</aside>}}

`__kernel void m01415_mxx`
: Invoked to handle cracking multiple target hashes at once. We can ignore this during testing.

`__kernel void m01415_sxx`
: Invoked in single-hash mode (which is how we're testing). We can focus our development effort here.

Let's take a walk through the donor kernel's `m01410_sxx` function:

{{<code "The first block of the `m01410_sxx` function." >}}
{{<highlight c>}}/**
* digest
*/
const u32 search[4] =
{
	digests_buf[digests_offset].digest_buf[DGST_R0],
	digests_buf[digests_offset].digest_buf[DGST_R1],
	digests_buf[digests_offset].digest_buf[DGST_R2],
	digests_buf[digests_offset].digest_buf[DGST_R3]
};{{</highlight>}}
{{</code>}} 

In this kernel, Hashcat doesn't bother comparing all the bytes in the hash buffer — a basic optimization technique. It's unlikely to collide with a human-meaningful candidate as selected by Hashcat, even when doing partial matches. The bytes are configured in the `dgst_pos`* values of the `hashconfig` `struct`:

{{<code "Our mode's `dgst_pos`* values from `interface.c`." >}}
{{<highlight c>}}
hashconfig->dgst_pos0 = 3;
hashconfig->dgst_pos1 = 7;
hashconfig->dgst_pos2 = 2;
hashconfig->dgst_pos3 = 6;
{{</highlight>}}
{{</code>}} 


Use values from another kernel that has the same final hash round as your target.

{{<code "`m01410_sxx` preps `s[]` for `sha256` so it can be appended before finalization." >}}
{{<highlight c>}}/**
* base
*/
COPY_PW (pws[gid]);
const u32 salt_len = salt_bufs[salt_pos].salt_len;
u32 s[64] = { 0 };
for (int i = 0, idx = 0; i < salt_len; i += 4, idx += 1)
{
	s[idx] = swap32_S (salt_bufs[salt_pos].salt_buf[idx]);
}{{</highlight>}}
{{</code>}} 

The kernel prepares the salt buffer once and carries out operations usually performed by the Hashcat `sha256` library's `sha256_update_swap` function.

Now is a good time to browse through the methods in `inc_hash_sha256.cl`[^inc_hash_sha256]. These aren't documented in any way, and while they resemble other low-level C crypto implementations, some things have been changed to permit more efficient cracking. It helps to select methods out of this library, and those in its hash family (e.g., `sha512`, `sha1`), to understand how these functions can be used in various contexts.[^shaex]

[^inc_hash_sha256]: https://github.com/hashcat/hashcat/blob/master/OpenCL/inc_hash_sha256.cl

[^shaex]: https://github.com/hashcat/hashcat/search?q=inc_hash_sha256.cl

The function's main loop permutes the password root candidate `tmp.i` according to rules identified in the `rules_buf` array. It then establishes a `sha256` context, updates the context with the password candidate buffer, updates it (minus the swap already performed) with the salt, and then finalizes the hash. It then compares the bytes outlined in `hashconfig->dgst_pos`* for a match.

Because our source function is `sha256($plain.$salt)` and our target is `sha256(sha256($plain).$salt)`, we know we need to add a round of `sha256` to the plaintext before updating the final `sha256` context, `ctx`.

In my case, it took a few attempts to get the bit shifting / byte ordering correct. Here's what I did:

We know, ultimately, that `w0`, `w1`, `w2`, and `w3` needed to hold the ASCII representation of the `sha256` hash, using our example 'peanut':


Using these hardcoded values, Hashcat passes the self-test... Progress!

We can play with byte ordering and bit shifting until `w0[0]` holds `0x35353039` (which, unless you're shifting on a regular basis, isn't natural):

You can debug the kernel by alternating `rm -rf ./hashcat/kernels` with your Hashcat single-hash test command *e.g.* `./hashcat -m 1415 -a 0 “00050655d5d6b8a8c14d52e852ce930fcd38e0551f161d71999860bba72e52aa:b4d93efdf7899fed0944a8bd19890a72764a9e169668d4c602fc6f1199eea449” peanut.txt`. This is how I nailed down byte ordering and conversion.

With the right values in `w0`, `w1`, `w2`, and `w3`, we can move the *`_sxx` changes over to *`_mxx`. Just reapply your changes there while making sure the final comparison function is `COMPARE_M` instead of `COMPARE_S`.

## Results

{{<img "hcresult" "Running our new XenForo kernel." >}}

On an eight Nvidia 1080 GPU cracking rig from [sagitta](https://sagitta.pw/hardware/gpu-compute-nodes/brutalis/), we hit 605 MH/s with this unoptimized kernel — 7 times faster than CPU mode.

I'll need to wait for another rainy day (and a corpus with a shorter salt) to hack on an optimized kernel.

You can find the final implementation at this [GitHub Gist](https://gist.github.com/tbiehn/28531fdb324baaeaa2960aae1b9b36ab).