![alt tag](https://github.com/XlogicX/ARMaHYDAN/blob/master/arm2.png)
# ARMaHYDAN
A tool for manipulating 'optional' bits in ARM processor instructions. The tool gets its name by paying homage to a much older tool called HYDAN (a stegonography tool for x86 executables).<br>

# THEORY
It would be best to explain with an example. We will use the MOV (register) form instruction for all of our examples. In assembly language, its format is:<br>
MOV Rd, Rm<br>
This instruction copies what is in register Rm and places it in the Rd register. Any of the 16 registers can be used for this. An example of a valid instruction like this would be:<br>
MOV r0, r7<br>

What is actually relevant for the purposes of this tool though is how this instruction is encoded; the 1's and 0's of it. Below is a crude ASCII-text table of what all 32 bits mean for this instruction:<br>
```31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00```<br>
```___cond____|_0__0|_0|_1__1__0__1|_S|(0)(0)(0)(0)____Rd_____|_0__0__0__0__0__0__0__0|____Rm_____```<br>

There are 4 bits for what condition to execute the instruction under (equal, greater than, unconditional, etc...). If the S bit is set, the condition flags can be written to. You will see Rd and Rm, these are the destination and source registers. You will also so a bunch of 1's and 0's that you can't change. It is somewhat of a simplification to say this, but these are the bits that make this instruction a MOV instruction like this. If you change these bits, it becomes a different instruction. However, the focus of this tool is regarding the bit's in the parenthesis; the 0 bits in bit 19-16. It would seem that these bits are 'optional' (undocumented). Changing these bits doesn't appear to change the operation of the instruction at all. A disassembler, however, will usually decode these instructions as UNDEFINED (even though they still execute with no issue).<br>

Some instructions have more than 4 optional bits. Some of the instructions have these bits scattered all over the instruction. These bits are not always 0's, they just happen to be in the MOV example. Just for a show of variety, here is the MRS instruction:<br>
```31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00```<br>
```____cond___|_0__0__0__1__0|_0|_0__0|(1)(1)(1)(1)|___Rd_____|(0)(0)_0|(0)_0__0__0__0|(0)(0)(0)(0)```<br>

ARMaHYDAN attempts to make clever use out of the fact that these bits are so moldable. Below are some of the use cases.<br>

# UNDEFINING
Syntax: ./ARMaHYDAN.pl -u -i input_program -o undefined_program<br>

The -u argument is what specifies that we are 'undefining' instructions.<br>
Supply the -i argument with a normal program that you want to modify.<br>
The -o argument specifies an output program that will have many of its instructions look UNDEFINED to a disassembler.<br>

Not all instructions have optional bits (it is close to between a 3rd or 4th of them). However, not even all of these remaining instructions look undefinable when modifying the optional bits. Also, even for those that can be undefined, you can't just change any of the bits (some changes still leave the instruction looking defined). The -u argument will hand pick just those instructions that can be 'undefined' and change just the right bits to do that.<br>

# RANDOM
Syntax: ./ARMaHYDAN.pl -r -i input_program -o randomized_program<br>

The -r argument is what specifies that we are 'randomizing' instructions.<br>
Supply the -i argument with a normal program that you want to modify.<br>
The -o argument specifies an output program that will have many of its instructions with randomized optional bits<br>

This argument can affect all instructions with optional bits. In this case we don't care about them looking undefined, we are just looking to flip the bits randomly. This could be a simple way to change the hash of an executable without changing its function nor filesize. It could also be used as decoy data as a 'stego' executable. Although this last use case wouldn't be too effective.<br>

# RESET<br>
Syntax: ./ARMaHYDAN.pl -z -i input_program -o sanitized_program<br>

The -z argument is what specifies that we are resetting/defaulting instructions.<br>
Supply the -i argument with a normal or already modified program that you want to change.<br>
The -o argument specifies an output program that will have many of its instructions reset to a default state.<br>

The above verbiage was careful to say that many of the instructions will be set back to their default state. For reasons that can be read about further down in this documentation, some of these instructions may be skipped.<br>

The use case for this is to take a modified (by ARMaHYDAN) program and change the instructions back to a default state. This is one of the least effective use cases of this entire tool. Mostly becuase due to the way the program works, it may not be able to reset all of the instructions, leaving the original executable (before ARMaHYDAN touched it in the first place) in a better default state. This argument was only included becuase it was just another possible way to process the bits.<br>

# STEGANOGRAPHY (ENCODE)
Syntax: ./ARMaHYDAN -c cover_program -i encoded_file -o output_program<br>
The -c argument is a program that we want our output program to look and run like. It is what is considered a 'cover' file in stego lingo<br>
The -i argument is NOT an input program in this case, it is the secret message you want embedded into the cover program (although it can be a secret program if you want...).<br>
The -o argument is for the output program, this is the program that will look and work like the cover program, with the difference that it has data encoded into it as well.<br>

This use case allows you to hide a file inside an executable without affecting its operation or even its file size. This will obviously affect the hash value of the resulting program, however. Some executables don't make suitable cover programs, which will be elaborated on in the 'code vs data' section later in this doc.<br>

# STEGANOGRAPHY (DECODE)
Syntax ./ARMaHYDAN -e encoded_program -o secret_output<br>
The -e argument is for the executable that has a secret encoded into it<br>
The -o argument will be a file that has the data of the secret encoded data<br>

It should be note that very little metadata is used, becuase injectable data is so scarce already, and other complications (code vs data). While there is metadata for the filesize, there is not metadata for the original file name. You can call the output file whatever you'd like (i.e. output.bin). If you don't know what kind of file the output will be, that's fine; use your typical analysis tools to figure that out (xxd, file, etc...). At least the file size is handled for you.<br>

# STEGANALYSIS / INFORMATIONAL LISTING
Syntax ./ARMaHYDAN -i mystery_program -l<br>

First of all, the -l argument can be used to get some basic information about an input executable without actually modifying the bits. The most important thing it reports is how many bytes are injectable. This factors in an instruction blacklist (instructions that wont be modified), and the bytes used for metadata. This argument also shows the filesize of the program (which is nothing new to the ls command). We also have some statistics about the instruction blacklist, which will be elaborated more in the code vs data section.<br>

Finally, just as HYDAN was easily defeatable soon after its release, ARMaHYDAN is being released pre-defeated. This kind of stego is just too detectable and not recommended for anything serious. Knowing that there is a fairly consistent default to these bits, of course it is 'noisy' when these bits deviate. Although, without truly addressing the code vs data problem, detection isn't completely precise. There are four main heuristics that the steganalysis checks for. Some of it may not yet make sense without reading the code vs data section. Each indicator is preceded by a + (indicates stego/modifications) or - (indicates lack of stego/modifications indications). Some indicators are weaker than others.<br>

1. Data to instructions ratio. A normal ratio for an unmodified program is below .13. Although there are exceptions and the spread ins't linear. That is why this is just an indicator that is reported on. This is a pretty good indicator, but not bullet proof<br>

2. Metadata for file size. Only stego'd output programs would have valid data for this. This heuristic parses the value out as if it were stego'd regardless. It also factors in what the highest theoretical injectable data could be (becuase the calculated value from binary could be inacurate in this use case). Metadata that reports a size of 0 is a HIGH indicator stego was not used; it would mean a filesize of 0 bytes. 0 is also a very common value to get by chance from normal unmodified executables. If the metadata for the file size is larger than the maximum possible size injectable, then we also know that this is not stego, it could still be modified by some of the other arguments, or unmodified completely.<br>

3. This is regarding blacklisted instructions. Most stego'd executables don't generally have a blacklist much higher than 10. Not to say that input executables don't easily have higher values than that, but once the blacklist level gets higher than 10, they become less suitable for the stego to work. The reasons for this are complicated and are explained elsewhere. This heuristic reports on whether this value from metadata is in a plausible range for a stego'd executable.<br>

4. This final hueristic is weak, but still used becuase we have the data. For this, we calculate what the blacklist should be for this executable, and compare it to what the metadata states it would be. It compares the two values for plausibility. Although there are many reasons that either of these values are going to be a little bit wrong.<br>

# VERBOSITY
The -v argument can be used in most cases. It reports on some internal information and processes as the program executes. Depending on the arguments used, this script may have to make anywhere from 2 to 4 passes through the instructions it is processing. The verbose argument will at least tell you what pass it is on and also what information the pass is intending to process.<br>

This argument will also not only report on the instruction blacklist level, but which specific instructions were blacklisted. Finally, the ammount of instructions in this program that have optional bits is displayed.<br>

# CODE VS DATA
This issue was problematic. Even though ARMaHYDAN only processes data in the .text section of ELF binaries, not all data in the .text section is code. There is not a simple way that I know of the destinguish code from data that I know of. I state that relative to the complexity of ARMaHYDAN itself. There are likely good solutions to this problem, but I feel that those solutions are much more complex than this program itself; and ARMaHYDAN isn't serious enough to go down that road. Instead, a mitigation was taken. <br>

Of the data that false positives as instructions, ranking those instructions from most to least frequent is much different than a ranking of most frequent instructions that are actually found. This means that we can just not process the most frequent false positive instruction and not really lose much. But we don't want to eliminate more than we have too. ARMaHYDAN makes a pass to actually collect instructions that are likely to be false positive (these are instructions that already have their optional bits in an invalid state). It stores this value as metadata so the decoding argument can colloborate correctly. Of course there are edge-cases and exceptions to this simplicity, most of which are also handled.<br>

That said, sometimes there is still the false negative problem. Sometimes the blacklist wasn't agressive enough. When this happens, the stego still works, but the output program doesn't (segfualt is a common issue). This is a reason for recommending that you test your results after running. In the case that you got a seg fault on our resulting program, there is an over-ride argument for the blacklist (-s). You an specify a higher and higher value until your program stops segfaulting. Syntax would look like below:<br>
Syntax: ./ARMaHYDAN -c cover_program -i encoded_file -o output_program -s 9<br>

This will black list the top 9 commonly false positiving instructions (data). For all of the arguments other than stego, you will eventually find a value high enough to stop segfaulting. However, for stego, once you get above about -s 10, you will eventually run into an over-ride number that will give you an abort error that the cover program is not suitable for stego. This situation is an odd edge case, and one that ARMaHYDAN doesn't have a solution for.
