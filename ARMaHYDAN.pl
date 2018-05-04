#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;
use File::Find;

my $storage;
my $unconditional_storage;
my $goodops_storage;
my $weird_ops;	#instructions that deviate from ARM Manual recommended bits
my $c_ops;	#Changable Opcodes
my $filesize;
my $dsize;
my $skipped_ops_level = 0;
my $skipped_ops_level_alt = 0;
my $stegcount = 0;
my $profile = 'no';
my $sizecheck = 'no';
my $passes = 0;     #how many passes has the data been processed
my @random_bits;	#Array to store some random 1's and 0's
my $extraction = ''; 					#Extracted data
my @bits;	#Array of all 1's and 0's of injectable file
my $full_bit_size = '';
my %instructions = ('MOV_IMM_A1'=>0, 'MOV_REG_A1'=>0, 'ASR_IMM_A1'=>0, 'ASR_REG_A1'=>0,
        'BLX_REG_A1'=>0, 'BX_A1'=>0, 'BXJ_A1'=>0, 'CLREX_A1'=>0, 'CLZ_A1'=>0, 'CMN_IMM_A1'=>0,
        'CMN_REG_A1'=>0, 'CMN_REGS_A1'=>0, 'CMP_IMM_A1'=>0, 'CMP_REG_A1'=>0, 'CMP_REGS_A1'=>0,
        'DBG_A1'=>0, 'DMB_A1'=>0, 'DSB_A1'=>0, 'ISB_A1'=>0, 'LDRD_LIT_A1'=>0, 
        'LDRD_REG_A1'=>0, 'LDREX_A1'=>0, 'LDREXB_A1'=>0, 'LDREXD_A1'=>0, 'LDREXH_A1'=>0,
        'LDRH_REG_A1'=>0, 'LDRHT_A2'=>0, 'LDRSB_REG_A1'=>0, 'LDRSBT_A2'=>0, 'LDRSH_REG_A1'=>0,
        'LDRSHT_A2'=>0, 'LSL_IMM_A1'=>0, 'LSL_REG_A1'=>0, 'LSR_IMM_A1'=>0, 'LSR_REG_A1'=>0,
        'MRS_A1'=>0, 'MSR_IMM_A1'=>0, 'MSR_REG_A1'=>0, 'MUL_A1'=>0, 'MVN_IMM_A1'=>0,
        'MVN_REG_A1'=>0, 'MVN_REGS_A1'=>0, 'NOP_A1'=>0, 'PLD_IMM_A1'=>0, 'PLD_LIT_A1'=>0,
        'PLD_REG_A1'=>0, 'PLI_IMM_A1'=>0, 'PLI_REG_A1'=>0, 'QADD_A1'=>0, 'QADD16_A1'=>0,
        'QADD8_A1'=>0, 'QASX_A1'=>0, 'QDADD_A1'=>0, 'QDSUB_A1'=>0, 'QSAX_A1'=>0, 'QSUB_A1'=>0,
        'QSUB16_A1'=>0, 'QSUB8_A1'=>0, 'RBIT_A1'=>0, 'REV_A1'=>0, 'REV16_A1'=>0, 'REVSH_A1'=>0,
        'ROR_IMM_A1'=>0, 'ROR_REG_A1'=>0, 'RRX_A1'=>0, 'SADD16_A1'=>0, 'SADD8_A1'=>0,
        'SASX_A1'=>0, 'SDIV_A1'=>0, 'SEL_A1'=>0, 'SETEND_A1'=>0, 'SEV_A1'=>0, 'SHADD16_A1'=>0,
        'SHADD8_A1'=>0, 'SHASX_A1'=>0, 'SHSAX_A1'=>0, 'SHSUB16_A1'=>0, 'SHSUB8_A1'=>0,
        'SMUL_A1'=>0, 'SMULW_A1'=>0, 'SSAT16_A1'=>0, 'SSAX_A1'=>0, 'SSUB16_A1'=>0, 'SSUB8_A1'=>0,
        'STRD_REG_A1'=>0, 'STREX_A1'=>0, 'STREXB_A1'=>0, 'STREXD_A1'=>0, 'STREXH_A1'=>0,
        'STRH_REG_A1'=>0, 'STRHT_A2'=>0, 'SWP_A1'=>0, 'SXTAB_A1'=>0, 'SXTAB16_A1'=>0,
        'SXTAH_A1'=>0, 'SXTB_A1'=>0, 'SXTB16_A1'=>0, 'SXTH_A1'=>0, 'TEQ_IMM_A1'=>0,
        'TEQ_REG_A1'=>0, 'TEQ_REGS_A1'=>0, 'TST_IMM_A1'=>0, 'TST_REG_A1'=>0, 'TST_REGS_A1'=>0,
        'UADD16_A1'=>0, 'UADD8_A1'=>0, 'UASX_A1'=>0, 'UDIV_A1'=>0, 'UHADD16_A1'=>0,
        'UHADD8_A1'=>0, 'UHASX_A1'=>0, 'UHSAX_A1'=>0, 'UHSUB16_A1'=>0, 'UHSUB8_A1'=>0, 
        'UQADD16_A1'=>0, 'UQADD8_A1'=>0, 'UQASX_A1'=>0, 'UQSAX_A1'=>0, 'UQSUB16_A1'=>0,
        'UQSUB8_A1'=>0, 'USAT16_A1'=>0, 'USAX_A1'=>0, 'USUB16_A1'=>0, 'USUB8_A1'=>0,
        'UXTAB_A1'=>0, 'UXTAB16_A1'=>0, 'UXTAH_A1'=>0, 'UXTB_A1'=>0, 'UXTB16_A1'=>0,
        'UXTH_A1'=>0, 'VCVT_A1'=>0, 'VDUP_A1'=>0, 'VMOV_IMM_A2'=>0, 'VMOV_CR2S_A1'=>0,
        'VMOV_S2CR_A1'=>0, 'VMOV_REG_A1'=>0, 'VMRS_A1'=>0, 'VMSR_A1'=>0, 'WFE_A1'=>0,
        'WFI_A1'=>0, 'YIELD_A1'=>0);
my @skippables = ("ldrd (register) A1","strd (register) A1","strh (register) A1","mul A1","mrs A1",
        "ldrsb (register) A1","mvn (register) A1","ldrh (register) A1","ldrsh (register) A1",
        "tst (register) A1","mov (immediate) A1","mvn (immediate) A1","tst (immediate) A1",
        "cmp (register) A1","teq (register) A1","lsl (immediate) A1","cmn (register) A1",
        "cmn (immediate) A1","teq (immediate) A1","mvn (register shifted register) A1",
        "tst (register shifted register) A1","cmp (immediate) A1","qadd16 A1","qasx A1",
        "lsr (immediate) A1","asr (immediate) A1","swp A1","cmn (register shifted register) A1",
        "cmp (register shifted register)A1","msr (immediate) A1","smul A1",
        "teq (register shifted register) A1","ror (immediate) A1","lsl (register) A1","qadd A1",
        "qsub16 A1","qsax A1","mov (register) A1","setend A1","shadd16 A1","lsr (register) A1",
        "msr (register) A1","bxj A1","asr (register) A1","qadd8 A1","ror (register) A1",
        "sadd16 A1","bx A1","qsub8 A1","shasx A1","shsax A1","shsub16 A1","clz A1",
        "blx (register) A1","uadd16 A1","uasx A1","ldrexd A1","qdadd A1","usax A1","qdsub A1",
        "qsub A1","ldrex A1","strexd A1","strex A1","ldrexh A1","sadd8 A1","ldrexb A1","strexh A1",
        "shsub8 A1","uqsub16 A1","shadd8 A1","sasx A1","strexb A1","uqadd16 A1","ssub16 A1",
        "vmov (scalar to ARM core register) A1","sel A1","usub16 A1","ssax A1","uhsub16 A1",
        "uqsax A1","sdiv A1","uxtab16 A1","uhsax A1","usub8 A1","uqasx A1","uadd8 A1","ssub8 A1",
        "uhadd16 A1","sxtab16 A1","uqadd8 A1","ssat16 A1","rev A1","udiv A1","usat16 A1",
        "uhasx A1","uqsub8 A1","rbit A1","rev16 A1","uhadd8 A1","uhsub8 A1","sxtab A1","revsh A1",
        "sxtah A1","uxtab A1","vmov (register) A1","uxtah A1","vmrs A1","clrex A1","dbg A1",
        "dmb A1","dsb A1","isb A1","ldrd (litteral) A1","ldrht A2","ldrsbt A2","ldrsht A2",
        "nop A1","pld (immediate) A1","pld (litteral) A1","pld (register) A1","pli (immediate) A1",
        "pli (register) A1","rrx A1","sev A1","smulw A1","strht A2","sxtb A1","sxtb16 A1",
        "sxth A1","uxtb A1","uxtb16 A1","uxth A1","vcvt A1","vdup A1","vmov (immediate) A2",
        "vmov (ARM core register to scalar) A1","vmsr A1","wfe A1","wfi A1","yield A1");
my %options = ();
getopts("i:o:c:e:s:lzruhv", \%options);

        sanity();
        help() if defined $options{h};

        my $binary;
        my $outputfile = $options{o};
        my $filename;
        my $injected;
        if (defined $options{c}) {
                $filename = $options{c};
                $injected = $options{i};
        } elsif (not defined $options{e}) {
                $filename = $options{i};
        } else {
                $filename = $options{e} if defined $options{e};
        }



sub main () {
    #Process files
		find({ wanted => \&process_file, no_chdir => 1 }, $filename);
}

sub process_file {
	#Clear Values
	$storage = 0;
	$unconditional_storage = 0;
	$goodops_storage = 0;
	$weird_ops = 0;
	$c_ops = 0;
    $skipped_ops_level = 0;
    $stegcount = 0;
    $passes = 0;
    $extraction = '';
        my $file;
        my $elftest;
        #If it's a file
        if (-f $_) {
            $file = $_;
            $elftest = `file '$file'`;
            if ($elftest =~ /ELF 32-bit/) {
                print "\nProcessing $file:\n";
                if (defined $options{s}) {
                    $skipped_ops_level = $options{s};
                } elsif ((   (($options{i}) || ($options{r}) || ($options{z}) || ($options{u})) && !($options{l}))) {
                    #Need to profile first
                    $profile = 'yes';
                    print "Profiling Unusable Instructions:\n" if defined $options{v};
                    process_data($file);              
                } else {
                    print "Fetching Skippable Instructions:\n" if defined $options{v};
                    process_data($file);
                    $extraction = '';
                }
                my $temp_skip;
                if ($options{l}) {          
                    $temp_skip = $skipped_ops_level;             #temp = skipped = metadata
                    $profile = 'yes';
                    print "Profiling Unusable Instructions:\n" if defined $options{v};
                    process_data($file);
                    $skipped_ops_level_alt = $skipped_ops_level;    #alt = skipped = calculated
                    $skipped_ops_level = $temp_skip;                #skipped = temp = metadata
                    $c_ops = 0;
                }
                $profile = 'no';
                #check file size injectable
                if (($options{c}) || ($options{l})) {
                    $skipped_ops_level = $skipped_ops_level_alt if $options{l}; #need calculated                    
                    $sizecheck = 'yes';
                    print "Checking ammount of data that can be injected:\n" if defined $options{v};
                    process_data($file);
                    $skipped_ops_level = $temp_skip if $options{l};             #back to metadata version
                    $sizecheck = 'no';                       
                }                  
                $storage = 0 if $options{l};  
                $c_ops = 0 if $options {e};         
                print "Processing Instructions (Final Pass):\n" if defined $options{v};
                process_data($file);
                print "Convertable Instruction Patterns Matched: " . $c_ops . "\n" if defined $options{v};
                print "Total Storage (considering excluded ops and overhead): " . (($weird_ops / 8) - 5) . "\n" if defined $options{v};
                print "File Size is: $filesize\n" if ((defined $options{v}) && (defined $options{c}));
                if (defined $options{c}) {
                    if ($filesize > ($weird_ops / 8) - 5) {
                        print "Injected file is $filesize bytes, and we only have " . (($weird_ops / 8) - 5) . " to inject into.\n" if defined $options{v};
                        print "Data after " . (($weird_ops / 8) - 5) . " bytes wont be written\n" if defined $options{v};
                    }
                }
                $skipped_ops_level_alt = $skipped_ops_level if !($options{l});
                print "Exlusion Level (-s): $skipped_ops_level_alt\n" if defined $options{v};
                if (defined $options{v}) {
                    print "The following instructions get skipped:\n\t" if $skipped_ops_level_alt > 0;
                }
                while ($skipped_ops_level_alt > 0) {
                    print "$skippables[$skipped_ops_level_alt - 1], " if defined $options{v};
                    $skipped_ops_level_alt--;
                }               
                print "\nProcessing Instructions:\n" if defined $options{v};                
            }
        } else {
            if (!(defined $options{l})) {
                print "This argument only excpets a file (not a directory)\n";
                exit;
            }
        }
}
  


sub process_data {
    print "Starting Pass $passes...\n" if $options{v};
    my $file = shift;
    my ($text_start, $text_length) = get_elfdata($file);

    open FILE, "$file" or die "Couldn't open $file, $!\n";
    binmode(FILE);

    if (defined $options{o}) {
	   open OUTFILE, ">$outputfile" or die "Coudln't open $outputfile, $!\n";
	   binmode(OUTFILE);
    }

    #Read in the file for injection and convert to binary stream
    if (defined $options{c}) {
        open INJECTFILE, "$injected" or die "Couldn't open $injected, $!\n";
        my $byte;
        my $dsize = 0;
        #Collect Bits of Injected data
        while (read(INJECTFILE, my $word, 1)) {
            $byte = get_binary_byte($word);
            if ($byte =~ /(.)(.)(.)(.)(.)(.)(.)(.)/) {
                push @bits, $1; push @bits, $2; push @bits, $3; push @bits, $4;
                push @bits, $5; push @bits, $6; push @bits, $7; push @bits, $8;
                $dsize++;
            }
        }
        $filesize = $dsize;
        close INJECTFILE;
        if (($profile eq 'no') && ($sizecheck eq 'no')) {        
            #Structure of bits starts with integer of how many bytes to extract
            if ((($weird_ops / 8) - 5) < $dsize) {
                print "WARNING: Injecting $dsize bytes into " . (($weird_ops / 8) - 5) . " bytes of space. Your data will be truncated\n";
                $dsize = (($weird_ops / 8) - 5);
            }            
            $dsize = unpack("B32", pack("N", $dsize));
            my @dsize_bits = split(//, $dsize);
            @bits = (@dsize_bits, @bits);
            #After Profiling Weird Ops, also store integer of the ops to skip
            my $skipsize = unpack("B32", pack("N", $skipped_ops_level));
            $skipsize =~ s/^[01]{24}//;
            my @skipsize_bits = split(//, $skipsize); 
            @bits = (@skipsize_bits, @bits);
            $full_bit_size = @bits;
        }                      
    }

    my $i = 0;
    while (read(FILE, my $word, 4)) {
        if (($i > ($text_start - 1)) && ($i < ($text_start + $text_length))) {
        #If the WORD is in range of the .text file, convert if possible
            #Get WORD in binary form
            $binary = get_binary($word);	
    
            #Process the Instruction
            $binary = reverse_endian($binary);
            $binary = process_instruction($binary);
            $binary = reverse_endian($binary);

            #Pack the new instruction back up and output it
            my $new_word = pack 'B32' => $binary;
            print OUTFILE $new_word if defined $options{o} && not defined $options{e};
        } else {
            #Otherwise, pass-through and write identical copy
            print OUTFILE $word if defined $options{o} && not defined $options{e};
        }
        $i++;
    }
    close FILE;

    if (((defined $options{e}) || (defined $options{l})) && ($profile eq 'no') && ($sizecheck eq 'no')) {
        #Find out wich ops to skip
        if ($extraction =~ /^([01]{8})/) {
            $skipped_ops_level = unpack("N", pack("B32", substr("0" x 32 . $1, -32)));
            $extraction =~ s/^[01]{8}//;
        }
        my $filedata;       
        #Extract value of how much data to carve        
        if ($extraction =~ /^([01]{32})/) {
            $dsize = unpack("N", pack("B32", substr("0" x 32 . $1, -32)));
            $extraction =~ s/^[01]{32}//;
        }
        #Carve Data           
        my $dbyte;
        if (defined $options{e}) {
            #we just need metadata for skippable ops in this pass, dsize could be wrong (and very large)
            if ($passes eq 0) {
                $dsize = 9001 if $dsize > 9001;
            } 
            while ($dsize gt 0) {
                if ($extraction =~ /^([01]{8})/) {
                    $dbyte = $1;
                    $extraction =~ s/^[01]{8}//;
                    $dbyte = pack 'B8' => $dbyte;
                    print OUTFILE "$dbyte";
                }
                $dsize--;
            }
        }
    }

    if (defined $options{l}) {
        if (($profile eq 'no') && ($sizecheck eq 'no') && ($passes eq 3)) {
            my $full_filesize = -s $file;
            print "Filesize: $full_filesize\n";
            print "Injectable bytes: " . (($weird_ops / 8) - 5) . "\n";
            print "OPs that need skipping (calc/meta): $skipped_ops_level_alt / $skipped_ops_level\n";
            print "Code/Data Stats: $stegcount / $c_ops / " . $stegcount / $c_ops . "\n";
            print "Seganalysis:\n";
            if (($stegcount / $c_ops) > 0.13) {
                print "\t+ 'data' instructions ratio (" . $stegcount / $c_ops . ") is higher than the normal 0.13 (or lower) ratio\n";
            } else {
                print "\t- 'data' instructions ratio (" . $stegcount / $c_ops . ") is within a plausible ratio\n";
            }
            if ($dsize eq 0) {
                print "\t- Metadata would state the injected size is 0, ARMaHYDAN was very likely not used to inject data\n";
            } elsif (($storage / 8) > $dsize) {
                print "\t+ It is possible for $dsize bytes (from metadata) to fit in " . $storage / 8 . " bytes (highest possible theoretical) storage\n";
            } else {
                print "\t- It wouldn't be possible for $dsize bytes (from metadata) to fit in " . $storage /8 . " bytes (highest possible theoretical storage\n";
            }
            if (($skipped_ops_level < 11) && ($skipped_ops_level > 0)) {
                print "\t+ Metadata for 'data' instructions to avoid ($skipped_ops_level) is at a plausible level\n";
            } else {
                print "\t- Metadata for 'data' instructions to avoid ($skipped_ops_level) not at a plausible level\n";
            }           
            if ($skipped_ops_level > $skipped_ops_level_alt) {
                print "\t- Metadata for 'data' instructions to avoid greater than calculated level (injection very unlikely)\n";
            } else {
                print "\t+ Metadata for 'data' instructions to avoid is less than calculated level (very weak indicator)\n";
            }
            print "\n";                 
        }
    }
    $passes++;
    close OUTFILE;
}

sub sanity {
	#Run through use cases and make sure that options don't conflict in a silly way
	if (defined $options{c}) {
		if ((not defined $options{i}) || (not defined $options{o}) || (defined $options{e}) || (defined $options{l}) || (defined $options{z}) || (defined $options{r}) || (defined $options{u})) {
			print "Invalid combination of options for the use case of injecting data\n";
			exit;}}
	if (defined $options{e}) {
		if ((defined $options{i}) || (not defined $options{o}) || (defined $options{c}) || (defined $options{l}) || defined ($options {z}) || (defined $options{r}) || (defined $options{u})) {
			print "Invalid combination of options for the use case of extracting data\n";
			exit;}}
       if (defined $options{l}) {
                if ((not defined $options{i}) || (defined $options{o}) || (defined $options{c}) || (defined $options{e}) || (defined $options{z}) || (defined $options{r}) || (defined $options{u})) {
                        print "Invalid combination of options for the use case of listing injectable bytes\n";
                        exit;}}
       if (defined $options{z}) {
                if ((not defined $options{i}) || (not defined $options{o}) || (defined $options{c}) || (defined $options{e}) || (defined $options{l}) || (defined $options{r}) || (defined $options{u})) {
                        print "Invalid combination of options for the use case of clearing instructions back to default\n";
                        exit;}}
      if (defined $options{r}) {
                if ((not defined $options{i}) || (not defined $options{o}) || (defined $options{c}) || (defined $options{e}) || (defined $options{l}) || defined ($options {z}) || (defined $options{u})) {
                        print "Invalid combination of options for the use case of randomizing suggested bits\n";
                        exit;}}
      if (defined $options{u}) {
                if ((not defined $options{i}) || (not defined $options{o}) || (defined $options{c}) || (defined $options{e}) || (defined $options{l}) || defined ($options {z}) || (defined $options{r})) {
                        print "Invalid combination of options for the use case of detecting a stego'd executable\n";
                        exit;}}
}

sub help {
	print "NAME\n";
	print "\tARMaHYDAN - Script that manipulates 'suggested' bits in machine code of ARM ELF executables in various ways for various reasons\n\n";
	print "DESCRIPTION\n";
	print "\tA main use of this script would be for steganography; you can inject data into an executable without affecting file size nor function. You could also just put random bits in these stego areas as a decoy/distraction. There is also an option to place some hand selected bits into these areas for maximum 'UNDEFINED' looking instructions in objdump and other disassemblies. There is also a steganalysis option to detect executables that has a suspicious amount of modifications similar to what this script would do. There is also an option to take a modified executable and return the stego prone bits back to the defined values. Finally, there is a simple argument to just list how many bytes can be packed into an executable\n\n";
	print "OPTIONS\n";
	print "\t-i: used for specifying an input file\n";
	print "\t-o: used for specifying an output file; the modified file\n";
	print "\t-c: used to specify the 'cover' file; the program that data will be injected into. Note that the -i option will be our secret message and -o will be the the encoded output executable\n";
	print "\t-e: an input executable to extract stego'd data out of. You must specify an output file with the -o option; this is the result file for the stego\n";
	print "\t-l: List stats and steganalysis. Entire directories can be provided to -i (default recursive).\n";
	print "\t-z: Reset the changable bits back to default/defined state for an executable. Needs -i and -o\n";
	print "\t-r: Randomize the changable bits. Needs -i and -o\n";
	print "\t-u: Make these changeable bits look as undefined as possible to a dissasembler (while still executing the same). Needs -i and -o\n";
    print "\t-v: Shows more verbosity of internal steps gone through\n";
    print "\t-h: Displays this listing\n";
	print "EXAMPLES\n";
	print "\tUNDEFINE: ./ARMaHYDAN.pl -u -i input_program -o undefined_program\n";
    print "\tRANDOM: ./ARMaHYDAN.pl -r -i input_program -o randomized_program\n";
    print "\tRESET: ./ARMaHYDAN.pl -z -i input_program -o sanitized_program\n";
    print "\tSTEGO (encode) and VERBOSE: ./ARMaHYDAN -c cover_program -i encoded_file -o output_program -v\n";
    print "\tSTEGO (decode): ./ARMaHYDAN -e encoded_program -o secret_output\n";
    print "\tSTEGANALYS/STATS: ./ARMaHYDAN -i mystery_program -l\n";
	exit;
}

sub get_elfdata {
	my $name = shift;
	my $start;
	my $length;
	my $data = `readelf -a $name | grep '.text'`;
	if ($data =~ /\.text\s+\S+\s+\S+\s(\S+)\s+(\S+)/) {
		$start = $1;
		$length = $2;
	} 
	$start = (sprintf("%d", hex($start)))/4;
	$length = (sprintf("%d", hex($length)))/4;
	return ($start, $length);
}

sub get_binary {
	my $word = shift;
	my $bin = unpack('B32', $word);
	return $bin;
}

sub get_binary_byte {
        my $word = shift;
        my $bin = unpack('B8', $word);
        return $bin;
}

sub reverse_endian {
	my $bin = shift;
	if ($bin =~ /(.{8})(.{8})(.{8})(.{8})/) {
		$bin = "$4$3$2$1";
	}
	return $bin;
}

sub get_random_bits {
	@random_bits = '';
	for my $j (0..20) {
		push @random_bits, int(rand(2));
	}
}

sub process_instruction {
#Checks each instruction for undefinable conversions
	my $bin = shift;
	my $return;
        ($bin, $return) = op_LDR_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_B($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mov_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STR_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_BL_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ADD_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmp_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mov_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ADD_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_SUB_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmp_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_AND_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDM_LDMIA_LDMFD($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDRB_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDR_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_CDP($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STMDB_STMFD($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STRB_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_lsl_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDC_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_AND_REGS($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_blx_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_AND_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ORR_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_SUB_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_SVC($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STC($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_EOR_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STR_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mvn_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDRH_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_tst_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_bx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STM_STMIA_STMEA($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mul_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STRH_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_MCR($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDRD_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ORR_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STMDA_STMED($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_RSB_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_BIC_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STRD_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrd_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_asr_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strd_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmn_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDRB_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strh_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrex_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strex_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_MOV_IMM_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_STRB_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_RSB_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmrs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmov_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_MLA($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ADC_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_EOR_REGS($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_lsl_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxtab_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_teq_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_MOVT($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrh_reg_A1($bin);
                return $bin if ($return eq 1);
       ($bin, $return) = op_SBC_REG($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_LDRSH_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_EOR_IMM($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mvn_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxtah_A1($bin);
                return $bin if ($return eq 1);
    	($bin, $return) = op_ldrsb_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_clz_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mrs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_tst_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrsh_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_teq_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ror_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_asr_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmn_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxtah_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_rev_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_mvn_regs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_smul_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_tst_regs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_msr_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_teq_regs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmp_regs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_swp_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxtab_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_cmn_regs_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qadd_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_rev16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qsub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qsax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_bxj_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_msr_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_setend_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ror_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qsub_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qsub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shsax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shsub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxtab16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qdadd_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrexd_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sdiv_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_qdsub_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strexd_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_usax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_udiv_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrexh_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sel_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strexh_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrexb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strexb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_shsub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqsub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ssub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_usub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqsub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ssax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqsax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxtab16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhsub16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_usub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uqasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhsax_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ssub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhadd16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_usat16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ssat16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_revsh_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhasx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_rbit_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhadd8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uhsub8_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vdup_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrd_lit_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_pld_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_pld_lit_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_yield_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sev_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxth_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_pld_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrht_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_strht_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_clrex_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_wfi_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxtb16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_lsr_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrsbt_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_dsb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_lsr_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_nop_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxtb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxtb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_uxtb16_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmsr_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmov_cr2s_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vcvt_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_isb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_dbg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmov_imm_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_pli_imm_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_ldrsht_A2($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_sxth_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_wfe_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_rrx_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_vmov_s2cr_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_pli_reg_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_dmb_A1($bin);
                return $bin if ($return eq 1);
        ($bin, $return) = op_smulw_A1($bin);
                return $bin if ($return eq 1);
	return $bin;
}

sub op_ldrd_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| P| U| 0| W| 0|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  0  1|    Rm
    #The 4 zero bits in ()'s can be modified. This instruction still looks defined when modifying these
    my $bin = shift;
    if ($bin =~ /(....)(000..0.0........)(....)(1101....)/) {
        #Checking space
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 1;
            return ($bin, 1);
        }
        #Profiling
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MOV_LDRD_REG_A1'}++;
                $skipped_ops_level = 1 if $skipped_ops_level < 2;
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;                                       #Just a basic counter that we've had a convertable op
        $storage += 4;                                  #count how much 'storage' we can pack in
        $unconditional_storage += 4 if ($1 eq "1110");  #Only count the storage if the op is unconditional    
        #If Injecting (Need to profile first)
        if ((defined $options{i}) && ($skipped_ops_level < 1)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        #Check for curruption in MetaData for blacklisted ops
        if ((defined $options{c}) && ($skipped_ops_level > 0)) {    #if encoding and I'm blacklisted
            my $bit_ammount = @bits;                        #How many bits still need encoding
            $bit_ammount = $full_bit_size - $bit_ammount;   #What is the difference from the total (how many are left)
            if ($bit_ammount < 8) {                         #If we are still on our first 8 bits (and we are on a blacklisted one currently)
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRD (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }        
        #If Extracting (Need to read from profile)
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 1)) { $extraction .= $3; }
        #If Randomizing (Need to profile first)
		if ((defined $options{r}) && ($skipped_ops_level < 1)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        #If Clearing/Resetting (Need to profile first)
        if ((defined $options{z}) && ($skipped_ops_level < 1)) { $bin = $1 . $2 . "0000" . $4; }
        #If Undefining, Need to profile first       
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strd_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| P| U| 0| W| 0|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.0........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 2;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'STRD_REG_A1'}++;
                $skipped_ops_level = 2 if $skipped_ops_level < 3;            
				$stegcount++;
			}
            return ($bin, 1);            
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 2)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }     
        if ((defined $options{c}) && ($skipped_ops_level > 1)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STRD (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }               
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 2)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 2)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 2)) { $bin = $1 . $2 . "0000" . $4; }    
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strh_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| P| U| 0| W| 0|    Rn     |    Rt     |(0)(0)(0)(0) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.0........)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 3;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'STRH_REG_A1'}++;
                $skipped_ops_level = 3 if $skipped_ops_level < 4;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 3)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        } 
        if ((defined $options{c}) && ($skipped_ops_level > 2)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STRH (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }                  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 3)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 3)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 3)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 3)) { $bin = $1 . $2 . "0001" . $4; }

        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mul_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  0  0  0  0| S|    Rd     |(0)(0)(0)(0)    Rm     | 1  0  0  1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(0000000.....)(....)(....1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 4;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MUL_A1'}++;
                $skipped_ops_level = 4 if $skipped_ops_level < 5;              
				$stegcount++;
			}                    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 4)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        } 
        if ((defined $options{c}) && ($skipped_ops_level > 3)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MUL. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }                
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 4)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 4)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 4)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mrs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0| 0| 0  0|(1)(1)(1)(1)|   Rd     |(0)(0) 0|(0) 0  0  0  0|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(00010000)(....)(....)(..)(0)(.)(0000)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 11 if $skipped_ops_level < 5;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "00") || ($7 ne "0") || ($9 ne "0000")) {
                $instructions{'MRS_A1'}++;
                $skipped_ops_level = 5 if $skipped_ops_level < 6; 
				$stegcount++;
			}
            return ($bin, 1);
        }    
        $c_ops++;
        $storage += 11;
        $unconditional_storage += 11 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 5)) {
            my $injection1 = '';
            my $injection2 = '';
            my $injection3 = '';
            my $injection4 = '';                        
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 5; $injection2 .= $bits[$n]; }                
                for (my $n=6; defined $bits[$n]; $n++) { last if $n > 6; $injection3 .= $bits[$n]; }
                for (my $n=7; defined $bits[$n]; $n++) { last if $n > 10; $injection4 .= $bits[$n]; }                
                $injection1 = '0000' | $injection1;  
                $injection2 = '00' | $injection2; 
                $injection3 = '0' | $injection3; 
                $injection4 = '0000' | $injection4; 
                splice @bits, 0, 11;                                     
            } else { $injection1 = $3; $injection2 = $5; $injection3 = $7; $injection4 = $9; }
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6 . $injection3 . $8 . $injection4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 4)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MRS. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }                   
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 5)) { $extraction .= "$3$5$7$9"; }        
		if ((defined $options{r}) && ($skipped_ops_level < 5)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 .
                "$random_bits[5]$random_bits[6]" . $6 . "$random_bits[7]" . $8 .
                "$random_bits[8]$random_bits[9]$random_bits[10]$random_bits[11]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 5)) { $bin = $1 . $2 . "1111" . $4 . "00" . $6 . "0" . $8 . "0000"; }                    
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrsb_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| P| U| 0| W| 1|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.1........)(....)(1101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 6;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRSB_REG_A1'}++;
                $skipped_ops_level = 6 if $skipped_ops_level < 7;
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 6)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 5)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRSB (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }            
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 6)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 6)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 6)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 6)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mvn_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  1  1| S|(0)(0)(0)(0)|   Rd     |      imm5    | type| 0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001111.)(....)(...........0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 7;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MVN_REG_A1'}++;
                $skipped_ops_level = 7 if $skipped_ops_level < 8;
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 7)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 6)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MVN (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }            
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 7)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 7)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 7)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrh_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| P| U| 0| W| 1|    Rn     |    RT     |(0)(0)(0)(0) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.1........)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 8;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRH_REG_A1'}++;
                $skipped_ops_level = 8 if $skipped_ops_level < 9;
				$stegcount++;
			}                   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 8)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 7)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRH (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }            
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 8)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 8)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 8)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 8)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrsh_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| P| U| 0| W| 1|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.1........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 9;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRSH_REG_A1'}++;
                $skipped_ops_level = 9 if $skipped_ops_level < 10;
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 9)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 8)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRSH (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }            
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 9)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 9)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 9)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 9)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_tst_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  0  0  0| 1|    Rn     |(0)(0)(0)(0)      imm5    | type| 0|    rm
    my $bin = shift;
    if ($bin =~ /(....)(00010001....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 10;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TST_REG_A1'}++;
                $skipped_ops_level = 10 if $skipped_ops_level < 11;
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 10)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 9)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TST (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }            
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 10)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 10)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 10)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mov_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 1| 1  1  0  1| S|(0)(0)(0)(0)|    Rd    |               imm12
    my $bin = shift;
    if ($bin =~ /(....)(0011101.)(....)(................)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 11;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MOV_IMM_A1'}++;
                $skipped_ops_level = 11 if $skipped_ops_level < 12;
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 11)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                        
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 10)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MOV (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }        
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 11)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 11)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 11)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 11)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mvn_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 1| 1  1  1  1| S|(0)(0)(0)(0)    Rd     |               imm12
    my $bin = shift;
    if ($bin =~ /(....)(0011111.)(....)(................)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 12;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MVN_IMM_A1'}++;
                $skipped_ops_level = 12 if $skipped_ops_level < 13;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;   
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 12)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 11)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MVN (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 12)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 12)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 12)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_tst_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 1| 1  0  0  0| 1|    Rn     |(0)(0)(0)(0)               imm12
    my $bin = shift;
    if ($bin =~ /(....)(00110001....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 13;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TST_IMM_A1'}++;
                $skipped_ops_level = 13 if $skipped_ops_level < 14;
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 13)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 12)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TST (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 13)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 13)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 13)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmp_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  0  1  0| 1|    Rn     |(0)(0)(0)(0)   imm5       | type| 0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010101....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 14;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMP_REG_A1'}++;
                $skipped_ops_level = 14 if $skipped_ops_level < 15;
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 14)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 13)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMP (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 14)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 14)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 14)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_teq_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  0  0  1| 1|    Rn     |(0)(0)(0)(0)     imm5     | type| 0|    Rm
    my $bin = shift;   
    if ($bin =~ /(....)(00010011....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 15;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TEQ_REG_A1'}++;
                $skipped_ops_level = 15 if $skipped_ops_level < 16;            
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 15)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 14)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TEQ (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 15)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 15)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 15)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_lsl_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |      imm5    | 0  0  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(.........000....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 16;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LSL_IMM_A1'}++;
                $skipped_ops_level = 16 if $skipped_ops_level < 17;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 16)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 15)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LSL (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 16)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 16)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }                
        if ((defined $options{z}) && ($skipped_ops_level < 16)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 16)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmn_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  0  1  1| 1|    Rn     |(0)(0)(0)(0)|   imm5      | type| 0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010111....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 17;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMN_REG_A1'}++;
                $skipped_ops_level = 17 if $skipped_ops_level < 18;
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 17)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 16)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMN (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 17)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 17)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 17)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmn_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 1| 1  0  1  1| 1|    Rn     |(0)(0)(0)(0)               imm12
    my $bin = shift;
    if ($bin =~ /(....)(00110111....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 18;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMN_IMM_A1'}++;
                $skipped_ops_level = 18 if $skipped_ops_level < 19;
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 18)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 17)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMN (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 18)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 18)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 18)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_teq_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 1| 1  0  0  1| 1|    Rn     |(0)(0)(0)(0)               imm12
    my $bin = shift;
    if ($bin =~ /(....)(00110011....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 19;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TEQ_IMM_A1'}++;
                $skipped_ops_level = 19 if $skipped_ops_level < 20;            
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 19)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 18)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TEQ (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 19)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 19)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 19)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mvn_regs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  1  1| S|(0)(0)(0)(0)|   Rd     |    Rs     | 0| type| 1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001111.)(....)(........0..1....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 20;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MVN_REGS_A1'}++;
                $skipped_ops_level = 20 if $skipped_ops_level < 21;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 20)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 19)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MVN (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 20)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 20)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 20)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_tst_regs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  0  0  0| 1|    Rn     |(0)(0)(0)(0)    Rs     | 0| type| 1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010001....)(....)(....0..1....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 21;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TST_REGS_A1'}++;
                $skipped_ops_level = 21 if $skipped_ops_level < 22;            
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 21)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 20)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TST (register shifted register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 21)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 21)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 21)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmp_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 1| 1  0  1  0| 1|    Rn     |(0)(0)(0)(0)                imm12
    my $bin = shift;
    if ($bin =~ /(....)(00110101....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 22;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMP_IMM_A1'}++;
                $skipped_ops_level = 22 if $skipped_ops_level < 23;            
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 22)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }
            $bin = $1 . $2 . $injection . $4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 21)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMP (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 22)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 22)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4; 
        }
        if ((defined $options{z}) && ($skipped_ops_level < 22)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 23;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QADD16_A1'}++;
                $skipped_ops_level = 23 if $skipped_ops_level < 24;            
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 23)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 22)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 23)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 23)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 23)) { $bin = $1 . $2 . "1111" . $4; } 
        if ((defined $options{u}) && ($skipped_ops_level < 23)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 24;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QASX_A1'}++;
                $skipped_ops_level = 24 if $skipped_ops_level < 25;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 24)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 23)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 24)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 24)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 24)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 24)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}
sub op_lsr_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |      imm5    | 0  1  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(.........010....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 25;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LSL_IMM_A1'}++;
                $skipped_ops_level = 25 if $skipped_ops_level < 26;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 25)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 24)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LSR (immediate. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 25)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 25)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 25)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 25)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_asr_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |    imm5      | 1  0  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(.........100....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 26;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'ASR_IMM_A1'}++;
                $skipped_ops_level = 26 if $skipped_ops_level < 27;            
				$stegcount++;
			}                   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4; 
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 26)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 25)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of ASR (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 26)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 26)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 26)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 26)) { $bin = $1 . $2 . "0010" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_swp_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0| B| 0  0|    Rn     |    Rt     |(0)(0)(0)(0) 1  0  0  1|    Rt2
    my $bin = shift;
    if ($bin =~ /(....)(00010.00........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 27;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'SWP_A1'}++;
                $skipped_ops_level = 27 if $skipped_ops_level < 28;            
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 27)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 26)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SWP. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 27)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 27)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 27)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 27)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmn_regs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  0  1  1| 1|    Rn     |(0)(0)(0)(0)    Rs     | 0| type| 1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010111....)(....)(....0..1....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 28;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMN_REGS_A1'}++;
                $skipped_ops_level = 28 if $skipped_ops_level < 29;            
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 28)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 27)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMN (register shifted register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 28)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 28)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 28)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_cmp_regs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  0  1  0| 1|    Rn     |(0)(0)(0)(0)    Rs     | 0| type| 1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010101....)(....)(....0..1....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 29;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'CMP_REGS_A1'}++;
                $skipped_ops_level = 29 if $skipped_ops_level < 30;            
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 29)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 28)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CMP (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 29)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 29)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 29)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_msr_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  1  1  0| 0| 1  0| mask| 0  0|(1)(1)(1)(1)              imm12
    my $bin = shift;
    if ($bin =~ /(....)(00110010..00)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 30;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'MSR_IMM_A1'}++;
                $skipped_ops_level = 30 if $skipped_ops_level < 31;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 30)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 29)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MSR (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 30)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 30)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 30)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 30)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_smul_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0  1  1  0|    Rd     |(0)(0)(0)(0)    Rm     | 1| M| N| 0|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(00010110....)(....)(....1..0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 31;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'SMUL_A1'}++;
                $skipped_ops_level = 31 if $skipped_ops_level < 32;            
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 31)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 30)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SMUL. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 31)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 31)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 31)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_teq_regs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  0  0  1| 1|    Rn     |(0)(0)(0)(0)    Rs     | 0| type| 1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010011....)(....)(....0..1....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 32;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'TEQ_REGS_A1'}++;
                $skipped_ops_level = 32 if $skipped_ops_level < 33;            
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 32)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 31)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of TEQ (register shifted register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 32)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 32)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 32)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ror_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |     imm5     | 1  1  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(.........110....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 33;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'ROR_IMM_A1'}++;
                $skipped_ops_level = 33 if $skipped_ops_level < 34;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 33)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 32)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of ROR (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 33)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 33)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 33)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 33)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_lsl_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |    Rm     | 0  0  0  1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(........0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 34;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LSL_REG_A1'}++;
                $skipped_ops_level = 34 if $skipped_ops_level < 35;            
				$stegcount++;
			}    
        return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 34)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 33)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LSL (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 34)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 34)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 34)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 34)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qadd_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0  0  0  0|    Rn     |    Rd     |(0)(0)(0)(0) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010000........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 35;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'QADD_A1'}++;
                $skipped_ops_level = 35 if $skipped_ops_level < 36;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 35)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 34)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QADD. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 35)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 35)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 35)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qsub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 36;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QSUB16_A1'}++;
                $skipped_ops_level = 36 if $skipped_ops_level < 37;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 36)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 35)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QSUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 36)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 36)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 36)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 36)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qsax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 37;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QSAX_A1'}++;
                $skipped_ops_level = 37 if $skipped_ops_level < 38;            
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 37)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 36)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QSAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 37)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 37)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 37)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 37)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_mov_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     | 0  0  0  0  0  0  0  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(....00000000....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 38;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'MOV_REG_A1'}++;
                $skipped_ops_level = 38 if $skipped_ops_level < 39;            
				$stegcount++;
			}           
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 38)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;
                splice @bits, 0, 4;                 #Remove them from our data array
                } else { $injection = $3; }                 #If there's no more injection data, effectively don't inject
            $bin = $1 . $2 . $injection . $4;                   #inject the bits in the right places
        }
        if ((defined $options{c}) && ($skipped_ops_level > 37)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MOV (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 38)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 38)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 38)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 38)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_setend_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  0  0  1  0  0  0  0|(0)(0)(0) 1|(0)(0)(0)(0)(0)(0) E|(0) 0  0  0  0|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(1111)(00010000)(...)(1)(......)(.)(.)(0000)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 14 if $skipped_ops_level < 39;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "000") || ($5 ne "000000") || ($7 ne "0") || ($9 ne "0000")) {
                $instructions{'SETEND_A1'}++;
                $skipped_ops_level = 39 if $skipped_ops_level < 40;            
				$stegcount++;
			}                    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 14;
        $unconditional_storage += 14;
        if ((defined $options{i}) && ($skipped_ops_level < 39)) {
            my $injection1 = '';
            my $injection2 = '';
            my $injection3 = '';
            my $injection4 = '';                        
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 2; $injection1 .= $bits[$n]; }
                for (my $n=3; defined $bits[$n]; $n++) { last if $n > 8; $injection2 .= $bits[$n]; }                
                for (my $n=9; defined $bits[$n]; $n++) { last if $n > 9; $injection3 .= $bits[$n]; }
                for (my $n=10; defined $bits[$n]; $n++) { last if $n > 13; $injection4 .= $bits[$n]; }                
                $injection1 = '000' | $injection1;  
                $injection2 = '000000' | $injection2; 
                $injection3 = '0' | $injection3; 
                $injection4 = '0000' | $injection4;  
                splice @bits, 0, 14;                                        
            } else { $injection1 = $3; $injection2 = $5; $injection3 = $7; $injection4 = $9; }
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6 . $injection3 . $8 . $injection4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 38)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SETEND. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 39)) { $extraction .= "$3$5$7$9"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 39)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]" . $4 . 
                "$random_bits[4]$random_bits[5]$random_bits[6]$random_bits[7]" . 
                "$random_bits[8]$random_bits[9]" . $6 . "$random_bits[10]" . $8 .
                "$random_bits[11]$random_bits[12]$random_bits[13]$random_bits[14]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 39)) { $bin = $1 . $2 . "000" . $4 . "000000" . $6 . "0" . $8 . "0000"; }
        if ((defined $options{u}) && ($skipped_ops_level < 39)) { $bin = $1 . $2 . $3 . $4 . "000001" . $6 . $7 . $8 . $9; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 40;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHADD16_A1'}++;
                $skipped_ops_level = 40 if $skipped_ops_level < 41;            
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 40)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 39)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 40)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 40)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }    
        if ((defined $options{z}) && ($skipped_ops_level < 40)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 40)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_lsr_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |    Rm     | 0  0  1  1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(........0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 41;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LSR_REG_A1'}++;
                $skipped_ops_level = 41 if $skipped_ops_level < 42;  
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 41)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;          
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 40)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LSR (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 41)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 41)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 41)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 41)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_msr_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0| 0| 1  0| mask| 0  0|(1)(1)(1)(1)(0)(0) 0|(0) 0  0  0  0|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(00010010..00)(......)(0)(.)(0000....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 7 if $skipped_ops_level < 42;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "111100") || ($5 ne "0")) {
                $instructions{'MSR_REG_A1'}++;
                $skipped_ops_level = 42 if $skipped_ops_level < 43;              
				$stegcount++;
			}                    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 7;
        $unconditional_storage += 7 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 42)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 5; $injection1 .= $bits[$n]; }
                for (my $n=6; defined $bits[$n]; $n++) { last if $n > 6; $injection2 .= $bits[$n]; }                              
                $injection1 = '000000' | $injection1;  
                $injection2 = '0' | $injection2;       
                splice @bits, 0, 7;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 41)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of MSR (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 42)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 42)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
            "$random_bits[5]$random_bits[6]" . $4 . "$random_bits[7]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 42)) { $bin = $1 . $2 . "111100" . $4 . "0" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 42)) { $bin = $1 . $2 . "111000" . $4 . $5 . $6; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_bxj_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0  0  1  0|(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1) 0  0  1  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010010)(............)(0010....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 43;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111111111") {
                $instructions{'BXJ_A1'}++;
                $skipped_ops_level = 43 if $skipped_ops_level < 44;              
				$stegcount++;
			}               
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 43)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection .= $bits[$n]; }
                $injection = '000000000000' | $injection;           
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 42)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of BXJ. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 43)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 43)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 43)) { $bin = $1 . $2 . "111111111111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 43)) { $bin = $1 . $2 . "111111111110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_asr_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0| 0| 1  1  0  1  S|(0)(0)(0)(0)    Rd     |    Rm     | 0  1  0  1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(........0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 44;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'ASR_REG_A1'}++;
                $skipped_ops_level = 44 if $skipped_ops_level < 45;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 44)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 43)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of ASR (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 44)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 44)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 44)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 44)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rd     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 45;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QADD8_A1'}++;
                $skipped_ops_level = 45 if $skipped_ops_level < 46;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 45)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 44)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 45)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 45)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 45)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 45)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ror_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     |    Rm     | 0  1  1  1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(........0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 46;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'ROR_REG_A1'}++;
                $skipped_ops_level = 46 if $skipped_ops_level < 47;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 46)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 45)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of ROR (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 46)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 46)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 46)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 46)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 47;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SADD16_A1'}++;
                $skipped_ops_level = 47 if $skipped_ops_level < 48;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 47)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 46)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 47)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 47)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 47)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 47)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_bx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0  0  1  0|(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010010)(............)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 48;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111111111") {
                $instructions{'BX_A1'}++;
                $skipped_ops_level = 48 if $skipped_ops_level < 49;              
				$stegcount++;
			}                   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 48)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) {
                    last if $n > 11;
                    $injection .= $bits[$n];
                }
                $injection = '000000000000' | $injection;      
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 47)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of BX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 48)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 48)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 48)) { $bin = $1 . $2 . "111111111111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 48)) { $bin = $1 . $2 . "111111101111" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qsub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100010........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 49;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'QSUB8_A1'}++;
                $skipped_ops_level = 49 if $skipped_ops_level < 50;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 49)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 49)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 49)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 48)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QSUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
        if ((defined $options{z}) && ($skipped_ops_level < 49)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 49)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 50;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHASX_A1'}++;
                $skipped_ops_level = 50 if $skipped_ops_level < 51;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 50)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 50)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 50)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 49)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
        if ((defined $options{z}) && ($skipped_ops_level < 50)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 50)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shsax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 51;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHSAX_A1'}++;
                $skipped_ops_level = 51 if $skipped_ops_level < 52;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 51)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 51)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 51)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 50)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHSAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
        if ((defined $options{z}) && ($skipped_ops_level < 51)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 51)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shsub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 52;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHSUB16_A1'}++;
                $skipped_ops_level = 52 if $skipped_ops_level < 53;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 52)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 51)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHSUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 52)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 52)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 52)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 52)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_clz_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0  1  1  0|(1)(1)(1)(1)    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010110)(....)(....)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 53;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'CLZ_A1'}++;
                $skipped_ops_level = 53 if $skipped_ops_level < 54;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 53)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;          
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 52)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CLZ. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 53)) { $extraction .= "$3$5"; }  
		if ((defined $options{r}) && ($skipped_ops_level < 53)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 53)) { $bin = $1 . $2 . "1111" . $4 . "1111" . $6; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_blx_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0  0  1  0|(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1)(1) 0  0  1  1|     Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010010)(............)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 54;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111111111") {
                $instructions{'BLX_REG_A1'}++;
                $skipped_ops_level = 54 if $skipped_ops_level < 55;              
				$stegcount++;
			}               
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 54)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection .= $bits[$n]; }
                $injection = '000000000000' | $injection;         
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 53)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of BLX (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 54)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 54)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 54)) { $bin = $1 . $2 . "111111111111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 54)) { $bin = $1 . $2 . "111111101111" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 55;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UADD16_A1'}++;
                $skipped_ops_level = 55 if $skipped_ops_level < 56;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 55)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 54)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 55)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 55)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 55)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 55)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 56;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UASX_A1'}++;
                $skipped_ops_level = 56 if $skipped_ops_level < 57;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 56)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 55)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 56)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 56)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 56)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 56)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrexd_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 1  1  0  1| 1|    Rn     |    Rt     |(1)(1)(1)(1) 1  0  0  1|(1)(1)(1)(1)
    my $bin = shift;
    if ($bin =~ /(....)(00011011........)(....)(1001)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 57;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'LDREXD_A1'}++;
                $skipped_ops_level = 57 if $skipped_ops_level < 58;              
				$stegcount++;
			}                
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 57)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 56)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDREXD. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 57)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 57)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 57)) { $bin = $1 . $2 . "1111" . $4 . "1111"; }
        if ((defined $options{u}) && ($skipped_ops_level < 57)) { $bin = $1 . $2 . "0000" . $4 . $5; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qdadd_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0  1  0  0|    Rn     |    Rd     |(0)(0)(0)(0) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010100........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 58;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'QDADD_A1'}++;
                $skipped_ops_level = 58 if $skipped_ops_level < 59;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 58)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 57)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QDADD. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 58)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 58)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 58)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_usax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 59;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'USAX_A1'}++;
                $skipped_ops_level = 59 if $skipped_ops_level < 60;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 59)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 58)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of USAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 59)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 59)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 59)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 59)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qdsub_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0  1  1  0|    Rd     |    Rd     |(0)(0)(0)(0) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010110........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 60;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'QDSUB_A1'}++;
                $skipped_ops_level = 60 if $skipped_ops_level < 61;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 60)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 59)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QDSUB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 60)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 60)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 60)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_qsub_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  0  0  1  0|    Rn     |    Rd     |(0)(0)(0)(0) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(00010010........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 61;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'QSUB_A1'}++;
                $skipped_ops_level = 61 if $skipped_ops_level < 62;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 61)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 60)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of QSUB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 61)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 61)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 61)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 61)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrex_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0  1  1  0  0| 1|    Rn     |    Rt     |(1)(1)(1)(1) 1  0  0  1|(1)(1)(1)(1)
    my $bin = shift;
    if ($bin =~ /(....)(00011001........)(....)(1001)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 62;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'LDREX_A1'}++;
                $skipped_ops_level = 62 if $skipped_ops_level < 63;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 62)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 61)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDREX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 62)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 62)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 62)) { $bin = $1 . $2 . "1111" . $4 . "1111"; }
        if ((defined $options{u}) && ($skipped_ops_level < 62)) { $bin = $1 . $2 . $3 . $4 . "1110"; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strexd_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| 1  1  0  1| 0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rt
    my $bin = shift;
    if ($bin =~ /(....)(00011010........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 63;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'STREXD_A1'}++;
                $skipped_ops_level = 63 if $skipped_ops_level < 64;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 63)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 62)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STREXD. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 63)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 63)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        } 
        if ((defined $options{z}) && ($skipped_ops_level < 63)) { $bin = $1 . $2 . "1111" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}
sub op_strex_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  1  0  0| 0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rt
    my $bin = shift;
    if ($bin =~ /(....)(00011000........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 64;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'STREX_A1'}++;
                $skipped_ops_level = 64 if $skipped_ops_level < 65;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 64)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 63)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STREX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 64)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 64)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 64)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 64)) { $bin = $1 . $2 . "1101" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrexh_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 1  1  1  1| 1|    Rn     |    Rt     |(1)(1)(1)(1) 1  0  0  1|(1)(1)(1)(1)
    my $bin = shift;
    if ($bin =~ /(....)(00011111........)(....)(1001)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 65;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'LDREXH_A1'}++;
                $skipped_ops_level = 65 if $skipped_ops_level < 66;              
				$stegcount++;
			}   
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 65)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;          
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 64)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDREXH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 65)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 65)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]";
            }
        if ((defined $options{z}) && ($skipped_ops_level < 65)) { $bin = $1 . $2 . "1111" . $4 . "1111"; }
        if ((defined $options{u}) && ($skipped_ops_level < 65)) { $bin = $1 . $2 . $3 . $4 . "1110"; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  0  1|    Rn     |     Rd    |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 66;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SADD8_A1'}++;
                $skipped_ops_level = 66 if $skipped_ops_level < 67;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 66)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 66)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 66)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{c}) && ($skipped_ops_level > 65)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 66)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 66)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrexb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 1  1  1  0| 1|    Rn     |    Rt     |(1)(1)(1)(1) 1  0  0  1|(1)(1)(1)(1)
    my $bin = shift;
    if ($bin =~ /(....)(00011101........)(....)(1001)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 67;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'LDREXB_A1'}++;
                $skipped_ops_level = 67 if $skipped_ops_level < 68;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;                
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 67)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;          
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 66)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDREXB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 67)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 67)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]";
            }
        if ((defined $options{z}) && ($skipped_ops_level < 67)) { $bin = $1 . $2 . "1111" . $4 . "1111"; }
        if ((defined $options{u}) && ($skipped_ops_level < 67)) { $bin = $1 . $2 . $3 . $4 . "1110"; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strexh_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| 1  1  1  1| 0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rt
    my $bin = shift;
    if ($bin =~ /(....)(00011110........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 68;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'STREXH_A1'}++;
                $skipped_ops_level = 68 if $skipped_ops_level < 69;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 68)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 67)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STREXH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 68)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 68)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 68)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 68)) { $bin = $1 . $2 . "1101" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shsub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 69;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHSUB8_A1'}++;
                $skipped_ops_level = 69 if $skipped_ops_level < 70;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 69)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 68)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHSUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 69)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 69)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 69)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 69)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);   
    }
    return ($bin, 0);
}

sub op_uqsub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 70;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQSUB16_A1'}++;
                $skipped_ops_level = 70 if $skipped_ops_level < 71;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 70)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;    
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 69)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQSUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 70)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 70)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 70)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 70)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_shadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100011........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 71;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SHADD8_A1'}++;
                $skipped_ops_level = 71 if $skipped_ops_level < 72;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 71)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;  
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 70)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SHADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 71)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 71)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 71)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 71)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  0  0  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 72;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SASX_A1'}++;
                $skipped_ops_level = 72 if $skipped_ops_level < 73;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 72)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;    
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 71)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 72)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 72)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 72)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 72)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strexb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| 1  1  1  0| 0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rt
    my $bin = shift;
    if ($bin =~ /(....)(00011100........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 73;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'STREXB_A1'}++;
                $skipped_ops_level = 73 if $skipped_ops_level < 74;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 73)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;    
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 72)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STREXB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 73)) { $extraction .= $3; }                
		if ((defined $options{r}) && ($skipped_ops_level < 73)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 73)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 73)) { $bin = $1 . $2 . "1101" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uqadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 74;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQADD16_A1'}++;
                $skipped_ops_level = 74 if $skipped_ops_level < 75;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 74)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection; 
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 73)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 74)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 74)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 74)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 74)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ssub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 75;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SSUB16_A1'}++;
                $skipped_ops_level = 75 if $skipped_ops_level < 76;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 75)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 74)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SSUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 75)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 75)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 75)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 75)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmov_s2cr_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0| U| opc1| 1|    Vn     |    Rt     | 1  0  1  1| N| opc2| 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(1110...1........1011...1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 76;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'VMOV_S2CR_A1'}++;
                $skipped_ops_level = 76 if $skipped_ops_level < 77;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 76)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 75)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMOV (scalar to ARM core register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 76)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 76)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 76)) { $bin = $1 . $2 . "0000"; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sel_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  1  0  0  0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101000........)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 77;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SEL_A1'}++;
                $skipped_ops_level = 77 if $skipped_ops_level < 78;              
				$stegcount++;
			}
            return ($bin, 1);
        }    
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 77)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 76)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SEL. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 77)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 77)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 77)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 77)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_usub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 78;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'USUB16_A1'}++;
                $skipped_ops_level = 78 if $skipped_ops_level < 79;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 78)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 77)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of USUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 78)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 78)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 78)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 78)) { $bin = $1 . $2 . "1110" . $4; }
  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ssax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 79;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SSAX_A1'}++;
                $skipped_ops_level = 79 if $skipped_ops_level < 80;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 79)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 78)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SSAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 79)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 79)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 79)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 79)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhsub16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 80;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHSUB16_A1'}++;
                $skipped_ops_level = 80 if $skipped_ops_level < 81;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 80)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 79)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHSUB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 80)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 80)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 80)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 80)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uqsax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 81;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQSAX_A1'}++;
                $skipped_ops_level = 81 if $skipped_ops_level < 82;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 81)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 80)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQSAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 81)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 81)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 81)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 81)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sdiv_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  1  0| 0  0  1|    Rd     |(1)(1)(1)(1)    Rm     | 0  0  0| 1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(01110001....)(....)(....0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 82;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SDIV_A1'}++;
                $skipped_ops_level = 82 if $skipped_ops_level < 83;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 82)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;         
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 81)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SDIV. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 82)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 82)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 82)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 82)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxtab16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  0  0|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101100..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 83;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTAB16_A1'}++;
                $skipped_ops_level = 83 if $skipped_ops_level < 84;  
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 83)) { 
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;       
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 82)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTAB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 83)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 83)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 83)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 83)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhsax_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 84;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHSAX_A1'}++;
                $skipped_ops_level = 84 if $skipped_ops_level < 85;  
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 84)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 83)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHSAX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 84)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 84)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 84)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 84)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_usub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 85;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'USUB8_A1'}++;
                $skipped_ops_level = 85 if $skipped_ops_level < 86;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 85)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 84)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of USUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 85)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 85)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 85)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 85)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uqasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 86;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQASX_A1'}++;
                $skipped_ops_level = 86 if $skipped_ops_level < 87;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 86)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                      
        }
        if ((defined $options{c}) && ($skipped_ops_level > 85)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 86)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 86)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 86)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 86)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100101........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 87;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UADD8_A1'}++;
                $skipped_ops_level = 87 if $skipped_ops_level < 88;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 87)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 86)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 87)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 87)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 87)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 87)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ssub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  0  0  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100001........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 88;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SSUB8_A1'}++;
                $skipped_ops_level = 88 if $skipped_ops_level < 89;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 88)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection; 
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 87)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SSUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 88)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 88)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 88)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 88)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhadd16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 89;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHADD16_A1'}++;
                $skipped_ops_level = 89 if $skipped_ops_level < 90;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 89)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 88)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHADD16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 89)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 89)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 89)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 89)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxtab16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  0  0|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101000..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 90;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTAB16_A1'}++;
                $skipped_ops_level = 90 if $skipped_ops_level < 91;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 90)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;         
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 89)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTAB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 90)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 90)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 90)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 90)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uqadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 91;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQADD8_A1'}++;
                $skipped_ops_level = 91 if $skipped_ops_level < 92;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 91)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 90)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 91)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 91)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 91)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 91)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ssat16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  1  0|  sat_imm  |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rn 
    my $bin = shift;
    if ($bin =~ /(....)(01101010........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 92;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'SSAT16_A1'}++;
                $skipped_ops_level = 92 if $skipped_ops_level < 93;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 92)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 91)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SSAT16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 92)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 92)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 92)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 92)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_rev_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  1| 0| 1  1|(1)(1)(1)(1)    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rd
    my $bin = shift;
    if ($bin =~ /(....)(01101011)(....)(....)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 93;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'REV_A1'}++;
                $skipped_ops_level = 93 if $skipped_ops_level < 94;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 93)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;        
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 92)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of REV. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 93)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 93)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 93)) { $bin = $1 . $2 . "1111" . $4 . "1111" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 93)) { $bin = $1 . $2 . $3 . $4 . "1110" . $6; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_udiv_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  1  0| 0  1  1|    Rd     |(1)(1)(1)(1)    Rm     | 0  0  0| 1|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(01110011....)(....)(....0001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 94;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UDIV_A1'}++;
                $skipped_ops_level = 94 if $skipped_ops_level < 95;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 94)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 93)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UDIV. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 94)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 94)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 94)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 94)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_usat16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  1  0|  sat_imm  |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101110........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 95;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'USAT16_A1'}++;
                $skipped_ops_level = 95 if $skipped_ops_level < 96;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 95)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 94)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of USAT16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 95)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 95)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 95)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 95)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhasx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 96;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHASX_A1'}++;
                $skipped_ops_level = 96 if $skipped_ops_level < 97;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 96)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 95)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHASX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 96)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 96)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 96)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 96)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uqsub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  0|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100110........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 97;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UQSUB8_A1'}++;
                $skipped_ops_level = 97 if $skipped_ops_level < 98;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 97)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 96)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UQSUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 97)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 97)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 97)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 97)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_rbit_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  1  1  1  1|(1)(1)(1)(1)    Rd     |(1)(1)(1)(1) 0  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101111)(....)(....)(....)(0011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 98;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'RBIT_A1'}++;
                $skipped_ops_level = 98 if $skipped_ops_level < 99;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 98)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 97)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of RBIT. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 98)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 98)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 98)) { $bin = $1 . $2 . "1111" . $4 . "1111" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 98)) { $bin = $1 . $2 . $3 . $4 . "1110" . $6; }      
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_rev16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  1| 0| 1  1|(1)(1)(1)(1)    Rd     |(1)(1)(1)(1) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101011)(....)(....)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 99;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'REV16_A1'}++;
                $skipped_ops_level = 99 if $skipped_ops_level < 100;              
				$stegcount++;
			}
            return ($bin, 1);
        }    
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 99)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;          
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 98)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of REV16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 99)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 99)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 99)) { $bin = $1 . $2 . "1111" . $4 . "1111" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 99)) { $bin = $1 . $2 . $3 . $4 . "1110" . $6; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhadd8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  0  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(1001....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 100;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHADD8_A1'}++;
                $skipped_ops_level = 100 if $skipped_ops_level < 101;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 100)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 99)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHADD8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 100)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 100)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 100)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 100)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uhsub8_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  0  1  1  1|    Rn     |    Rd     |(1)(1)(1)(1) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01100111........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 101;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'UHSUB8_A1'}++;
                $skipped_ops_level = 101 if $skipped_ops_level < 102;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 101)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 100)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UHSUB8. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 101)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 101)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 101)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 101)) { $bin = $1 . $2 . "1110" . $4; }  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxtab_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  1  0|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101010..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 102;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTAB_A1'}++;
                $skipped_ops_level = 102 if $skipped_ops_level < 103;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 102)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;      
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 101)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTAB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 102)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 102)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 102)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 102)) { $bin = $1 . $2 . "01" . $4; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_revsh_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  1  1  0  1| 1| 1  1|(1)(1)(1)(1)    Rd     |(1)(1)(1)(1) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101111)(....)(....)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 103;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1111") || ($5 ne "1111")) {
                $instructions{'REVSH_A1'}++;
                $skipped_ops_level = 103 if $skipped_ops_level < 104;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 103)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection1 .= $bits[$n]; }
                for (my $n=4; defined $bits[$n]; $n++) { last if $n > 7; $injection2 .= $bits[$n]; }                              
                $injection1 = '0000' | $injection1;  
                $injection2 = '0000' | $injection2;        
                splice @bits, 0, 8;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 102)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of REVSH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 103)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 103)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4 . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 103)) { $bin = $1 . $2 . "1111" . $4 . "1111" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 103)) { $bin = $1 . $2 . $3 . $4 . "1110" . $6; }  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxtah_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  1  1|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101011..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 104;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTAH_A1'}++;
                $skipped_ops_level = 104 if $skipped_ops_level < 105;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 104)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;       
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 103)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTAH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 104)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 104)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 104)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 104)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxtab_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  1  0|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101110..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 105;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTAB_A1'}++;
                $skipped_ops_level = 105 if $skipped_ops_level < 106;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 105)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;        
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 104)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTAB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 105)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 105)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 105)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 105)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmov_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0| 0  0  0|op|    Vn     |    Rt     | 1  0  1  0| N|(0)(0) 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(1110000.........1010.)(..)(1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 6 if $skipped_ops_level < 106;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "00") || ($5 ne "0000")) {
                $instructions{'VMOV_REG_A1'}++;
                $skipped_ops_level = 106 if $skipped_ops_level < 107;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 6;
        $unconditional_storage += 6 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 106)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection1 .= $bits[$n]; }
                for (my $n=2; defined $bits[$n]; $n++) { last if $n > 5; $injection2 .= $bits[$n]; }                              
                $injection1 = '00' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 6;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 105)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMOV (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 106)) { $extraction .= "$3$5"; }  
		if ((defined $options{r}) && ($skipped_ops_level < 106)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4 . 
                "$random_bits[3]$random_bits[4]$random_bits[5]$random_bits[6]";
        }      
        if ((defined $options{z}) && ($skipped_ops_level < 106)) { $bin = $1 . $2 . "00" . $4 . "0000"; } 
        if ((defined $options{u}) && ($skipped_ops_level < 106)) { $bin = $1 . $2 . $3 . $4 . "0010"; }                  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxtah_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  1  1|    Rn     |    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(01101111..........)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 107;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTAH_A1'}++;
                $skipped_ops_level = 107 if $skipped_ops_level < 108;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 107)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;        
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 106)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTAH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 107)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 107)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 107)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 107)) { $bin = $1 . $2 . "01" . $4; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmrs_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0  1  1  1  1| 0  0  0  1|    Rt     | 1  0  1  0|(0)(0)(0) 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(111011110001....1010)(...)(1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 7 if $skipped_ops_level < 108;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "000") || ($5 ne "0000")) {
                $instructions{'VMRS_A1'}++;
                $skipped_ops_level = 108 if $skipped_ops_level < 109;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 7;
        $unconditional_storage += 7 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 108)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 2; $injection1 .= $bits[$n]; }
                for (my $n=3; defined $bits[$n]; $n++) { last if $n > 6; $injection2 .= $bits[$n]; }                              
                $injection1 = '000' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 7;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 107)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMRS. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 108)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 108)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]" . $4 .
                "$random_bits[4]$random_bits[5]$random_bits[6]$random_bits[7]";
            } 
        if ((defined $options{z}) && ($skipped_ops_level < 108)) { $bin = $1 . $2 . "000" . $4 . "0000"; }
        if ((defined $options{u}) && ($skipped_ops_level < 108)) { $bin = $1 . $2 . "001" . $4 . $5; }               
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_clrex_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1  0  1  0  1  0  1  1  1|(1)(1)(1)(1)(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  1|(1)(1)(1)(1)
    my $bin = shift;
    if ($bin =~ /(1111)(01010111)(............)(0001)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 16 if $skipped_ops_level < 109;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "111111110000") || ($5 ne "1111")) {
                $instructions{'CLREX_A1'}++;
                $skipped_ops_level = 109 if $skipped_ops_level < 110;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 16;
        $unconditional_storage += 16;
        if ((defined $options{i}) && ($skipped_ops_level < 109)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection1 .= $bits[$n]; }
                for (my $n=12; defined $bits[$n]; $n++) { last if $n > 15; $injection2 .= $bits[$n]; }                              
                $injection1 = '000000000000' | $injection1;  
                $injection2 = '0000' | $injection2;       
                splice @bits, 0, 16;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 108)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of CLREX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 109)) { $extraction .= "$3$5"; }  
		if ((defined $options{r}) && ($skipped_ops_level < 109)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4 .
                "$random_bits[13]$random_bits[14]$random_bits[15]$random_bits[16]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 109)) { $bin = $1 . $2 . "111111110000" . $4 . "1111"; }
        if ((defined $options{u}) && ($skipped_ops_level < 109)) { $bin = $1 . $2 . $3 . $4 . "1110"; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_dbg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  1  1  0| 0| 1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 1  1  1  1|   option
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 110;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'DBG_A1'}++;
                $skipped_ops_level = 110 if $skipped_ops_level < 111;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 110)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;        
                splice @bits, 0, 8;                                        
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 109)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of DBG. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 110)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 110)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 110)) { $bin = $1 . $2 . "11110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 110)) { $bin = $1 . $2 . "11100000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_dmb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1  0  1  0  1  1  1|(1)(1)(1)(1)(1)(1)(1)(1)(0)(0)(0)(0) 0  1  0  1|   option
    my $bin = shift;
    if ($bin =~ /(1111)(01010111)(............)(0101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 111;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111110000") {
                $instructions{'DMB_A1'}++;
                $skipped_ops_level = 111 if $skipped_ops_level < 112;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12;
        if ((defined $options{i}) && ($skipped_ops_level < 111)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection .= $bits[$n]; }
                $injection = '000000000000' | $injection;          
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 110)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of DMB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 111)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 111)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 111)) { $bin = $1 . $2 . "111111110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 111)) { $bin = $1 . $2 . "111111110001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_dsb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1  0  1  0  1  1  1|(1)(1)(1)(1)(1)(1)(1)(1)(0)(0)(0)(0) 0  1  0  0|   option
    my $bin = shift;
    if ($bin =~ /(1111)(01010111)(............)(0100....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 112;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111110000") {
                $instructions{'DSB_A1'}++;
                $skipped_ops_level = 112 if $skipped_ops_level < 113;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12;
        if ((defined $options{i}) && ($skipped_ops_level < 112)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection .= $bits[$n]; }
                $injection = '000000000000' | $injection;          
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 111)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of DSB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 112)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 112)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
            }
        if ((defined $options{z}) && ($skipped_ops_level < 112)) { $bin = $1 . $2 . "111111110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 112)) { $bin = $1 . $2 . "111111110001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_isb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1  0  1  0  1  1  1|(1)(1)(1)(1)(1)(1)(1)(1)(0)(0)(0)(0) 0  1  1  0|   option
    my $bin = shift;
    if ($bin =~ /(1111)(01010111)(............)(0110....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 12 if $skipped_ops_level < 113;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "111111110000") {
                $instructions{'ISB_A1'}++;
                $skipped_ops_level = 113 if $skipped_ops_level < 114;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 12;
        $unconditional_storage += 12;
        if ((defined $options{i}) && ($skipped_ops_level < 113)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 11; $injection .= $bits[$n]; }
                $injection = '000000000000' | $injection;          
                splice @bits, 0, 12;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 112)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of ISB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 113)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 113)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" .
                "$random_bits[9]$random_bits[10]$random_bits[11]$random_bits[12]" . $4;
            }
        if ((defined $options{z}) && ($skipped_ops_level < 113)) { $bin = $1 . $2 . "111111110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 113)) { $bin = $1 . $2 . "111111110001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrd_lit_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0|(1) U| 1|(0) 0| 1  1  1  1|    Rt     |   imm4H   | 1  1  0  1|   imm4L
    my $bin = shift;
    if ($bin =~ /(....)(000)(.)(.1)(.)(01111........1101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 114;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1") || ($5 ne "0")) {
                $instructions{'LDRD_LIT_A1'}++;
                $skipped_ops_level = 114 if $skipped_ops_level < 115;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 114)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 0; $injection1 .= $bits[$n]; }
                for (my $n=1; defined $bits[$n]; $n++) { last if $n > 1; $injection2 .= $bits[$n]; }                              
                $injection1 = '0' | $injection1;  
                $injection2 = '0' | $injection2;       
                splice @bits, 0, 2;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 113)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRD (literal). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 114)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 114)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]" . $4 . "$random_bits[2]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 114)) { $bin = $1 . $2 . "1" . $4 . "0" . $6; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrht_A2 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 0| U| 0| 1| 1|    Rn     |    Rt     |(0)(0)(0)(0) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0000.011........)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 115;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRHT_A2'}++;
                $skipped_ops_level = 115 if $skipped_ops_level < 116;              
				$stegcount++;
			}
            return ($bin, 1);
        }    
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 115)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 114)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRHT (A2). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 115)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 115)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 115)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrsbt_A2 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 0| U| 0| 1| 1|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  0  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0000.011........)(....)(1101....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 116;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRSBT_A2'}++;
                $skipped_ops_level = 116 if $skipped_ops_level < 117;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 116)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 115)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRSBT (A2). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 116)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 116)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 116)) { $bin = $1 . $2 . "0000" . $4; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ldrsht_A2 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  0| 0| U| 0| 1| 1|    Rn     |    Rt     |(0)(0)(0)(0) 1  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(000..0.1........)(....)(1111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 117;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'LDRSHT_A2'}++;
                $skipped_ops_level = 117 if $skipped_ops_level < 118;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 117)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 116)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of LDRSHT (A2). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 117)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 117)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 117)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_nop_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0  1  1| 0  0  1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  0  0  0  0  0
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(00000000)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 118;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'NOP_A1'}++;
                $skipped_ops_level = 118 if $skipped_ops_level < 119;              
				$stegcount++;
			}
            return ($bin, 1);
        }     
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 118)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;       
                splice @bits, 0, 8;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 117)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of NOP. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 118)) { $extraction .= $3; }  
		if ((defined $options{r}) && ($skipped_ops_level < 118)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 118)) { $bin = $1 . $2 . "11110000" . $4; }   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_pld_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1| 0| 1| U| R| 0  1|    Rn     |(1)(1)(1)(1)               imm12
    my $bin = shift;
    if ($bin =~ /(1111)(0101..01....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 119;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'PLD_IMM_A1'}++;
                $skipped_ops_level = 119 if $skipped_ops_level < 120;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4;
        if ((defined $options{i}) && ($skipped_ops_level < 119)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 118)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of PLD (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 119)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 119)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 119)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 119)) { $bin = $1 . $2 . "1110" . $4; }    
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_pld_lit_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1| 0| 1| U|(1) 0  1| 1| 1  1  1|(1)(1)(1)(1)              imm12
    my $bin = shift;
    if ($bin =~ /(1111)(0101.)(.)(011111)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 5 if $skipped_ops_level < 120;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "1") || ($5 ne "1111")) {
                $instructions{'PLD_LIT_A1'}++;
                $skipped_ops_level = 120 if $skipped_ops_level < 121;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 5;
        $unconditional_storage += 4;
        if ((defined $options{i}) && ($skipped_ops_level < 120)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 0; $injection1 .= $bits[$n]; }
                for (my $n=1; defined $bits[$n]; $n++) { last if $n > 4; $injection2 .= $bits[$n]; }                              
                $injection1 = '0' | $injection1;  
                $injection2 = '0000' | $injection2;       
                splice @bits, 0, 5;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 119)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of PLD (literal). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 120)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 120)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]" . $4 . 
                "$random_bits[2]$random_bits[3]$random_bits[4]$random_bits[5]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 120)) { $bin = $1 . $2 . "1" . $4 . "1111" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 120)) { $bin = $1 . $2 . $3 . $4 . "1110" . $6; }                          
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_pld_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1| 1| 1| U| R| 0| 1|    Rn     |(1)(1)(1)(1)     imm5     | type| 0|    Rm
    my $bin = shift;
    if ($bin =~ /(1111)(0111..01....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 121;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'PLD_REG_A1'}++;
                $skipped_ops_level = 121 if $skipped_ops_level < 122;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4;
        if ((defined $options{i}) && ($skipped_ops_level < 121)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 120)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of PLD (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 121)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 121)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 121)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 121)) { $bin = $1 . $2 . "1110" . $4; }   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_pli_imm_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1  0  0| U| 1  0  1|    Rn     |(1)(1)(1)(1)               imm12
    my $bin = shift;
    if ($bin =~ /(1111)(0100.101....)(....)(............)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 122;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'PLI_IMM_A1'}++;
                $skipped_ops_level = 122 if $skipped_ops_level < 123;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4;
        if ((defined $options{i}) && ($skipped_ops_level < 122)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 121)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of PLI (immediate). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 122)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 122)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 122)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 122)) { $bin = $1 . $2 . "1110" . $4; }          
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_pli_reg_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
# 1  1  1  1| 0  1  1  0| U| 1  0  1|    Rn     |(1)(1)(1)(1)     imm5     | type| 0|    Rm
    my $bin = shift;
    if ($bin =~ /(1111)(0110.101....)(....)(.......0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 123;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "1111") {
                $instructions{'PLI_REG_A1'}++;
                $skipped_ops_level = 123 if $skipped_ops_level < 124;              
				$stegcount++;
			}    
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4;
        if ((defined $options{i}) && ($skipped_ops_level < 123)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 122)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of PLI (register). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 123)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 123)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 123)) { $bin = $1 . $2 . "1111" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 123)) { $bin = $1 . $2 . "1110" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_rrx_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#    cond   | 0  0| 0| 1  1  0  1| S|(0)(0)(0)(0)    Rd     | 0  0  0  0  0| 1  1  0|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0001101.)(....)(....00000110....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 124;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'RRX_A1'}++;
                $skipped_ops_level = 124 if $skipped_ops_level < 125;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 124)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 123)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of RRX. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 124)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 124)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 124)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 124)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sev_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  1  1  0| 0| 1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  0  0  1  0  0
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(00000100)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 125;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'SEV_A1'}++;
                $skipped_ops_level = 125 if $skipped_ops_level < 126;              
				$stegcount++;
			}
            return ($bin, 1);
        }   
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 125)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;        
                splice @bits, 0, 8;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 124)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SEV. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 125)) { $extraction .= $3; }  
		if ((defined $options{r}) && ($skipped_ops_level < 125)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;   
        }
        if ((defined $options{z}) && ($skipped_ops_level < 125)) { $bin = $1 . $2 . "11110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 125)) { $bin = $1 . $2 . "11100000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_smulw_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0  1  0  0  1  0|    Rd     |(0)(0)(0)(0)    Rm     | 1| M| 1| 0|    Rn
    my $bin = shift;
    if ($bin =~ /(....)(00010110....)(....)(....1..0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 126;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'SMULW_A1'}++;
                $skipped_ops_level = 126 if $skipped_ops_level < 127;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 126)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;     
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 125)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SMULW. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 126)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 126)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 126)) { $bin = $1 . $2 . "0000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 126)) { $bin = $1 . $2 . "0001" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_strht_A2 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  0| 0| U| 0| 1| 0|    Rn     |    Rt     |(0)(0)(0)(0) 1  0  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(0000.010........)(....)(1011....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 127;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'STRHT_A2'}++;
                $skipped_ops_level = 127 if $skipped_ops_level < 128;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 127)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;        
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 126)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of STRHT (A2). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 127)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 127)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 127)) { $bin = $1 . $2 . "0000" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxtb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  1  0| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011010101111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 128;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTB_A1'}++;
                $skipped_ops_level = 128 if $skipped_ops_level < 129;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 128)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;         
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 127)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 128)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 128)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 128)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 128)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxtb16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  0  0| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011010001111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 129;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTB16_A1'}++;
                $skipped_ops_level = 129 if $skipped_ops_level < 130;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 129)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;      
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 128)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 129)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 129)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 129)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 129)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_sxth_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  0  1  1| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011010111111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 130;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'SXTH_A1'}++;
                $skipped_ops_level = 130 if $skipped_ops_level < 131;              
				$stegcount++;
			}
            return ($bin, 1); 
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 130)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;       
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 129)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of SXTH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 130)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 130)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }  
        if ((defined $options{z}) && ($skipped_ops_level < 130)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 130)) { $bin = $1 . $2 . "01" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxtb_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  1  0| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011011101111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 131;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTB_A1'}++;
                $skipped_ops_level = 131 if $skipped_ops_level < 132;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 131)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;         
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 130)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTB. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 131)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 131)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 131)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 131)) { $bin = $1 . $2 . "01" . $4; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxtb16_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  0  0| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011011001111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 132;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTB16_A1'}++;
                $skipped_ops_level = 132 if $skipped_ops_level < 133;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 132)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;        
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 131)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTB16. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 132)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 132)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 132)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 132)) { $bin = $1 . $2 . "01" . $4; }   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_uxth_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  1  1  0  1  1  1  1| 1  1  1  1|    Rd     |rotat|(0)(0) 0  1  1  1|    Rm
    my $bin = shift;
    if ($bin =~ /(....)(011011111111......)(..)(0111....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 133;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "00") {
                $instructions{'UXTH_A1'}++;
                $skipped_ops_level = 133 if $skipped_ops_level < 134;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 133)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 1; $injection .= $bits[$n]; }
                $injection = '00' | $injection;        
                splice @bits, 0, 2;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 132)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of UXTH. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 133)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 133)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]" . $4;
        }     
        if ((defined $options{z}) && ($skipped_ops_level < 133)) { $bin = $1 . $2 . "00" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 133)) { $bin = $1 . $2 . "01" . $4; }  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vcvt_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0| 1| D| 1  1| 0  0  1|op|    Vd     | 1  0  1|(0) T| 1| M| 0|    Vm
    my $bin = shift;
    if ($bin =~ /(....)(11101.11001.....101)(.)(.1.0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 1 if $skipped_ops_level < 134;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0") {
                $instructions{'VCVT_A1'}++;
                $skipped_ops_level = 134 if $skipped_ops_level < 135;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 1;
        $unconditional_storage += 1 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 134)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 0; $injection .= $bits[$n]; }                            
                $injection = '0' | $injection;                    
                splice @bits, 0, 1;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 133)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VCVT. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }          
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 134)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 134)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 134)) { $bin = $1 . $2 . "0" . $4; }
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vdup_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0| 1| B| Q| 0|    Vd     |    Rt     | 1  0  1  1| D| 0| E| 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(11101..0........1011.0.1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 135;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'VDUP_A1'}++;
                $skipped_ops_level = 135 if $skipped_ops_level < 136;              
				$stegcount++;
			}
            return ($bin, 1);
        }  
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 135)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;      
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 134)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VDUP. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 135)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 135)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 135)) { $bin = $1 . $2 . "0000"; } 
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmov_imm_A2 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0  1| D| 1  1|   imm4H   |    Vd     | 1  0  1|sz|(0) 0|(0) 0|   imm4L
    my $bin = shift;
    if ($bin =~ /(....)(11101.11........101.)(.)(0)(.)(0....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 2 if $skipped_ops_level < 136;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "0") || ($5 ne "0")) {
                $instructions{'VMOV_IMM_A2'}++;
                $skipped_ops_level = 136 if $skipped_ops_level < 137;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 2;
        $unconditional_storage += 2 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 136)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 0; $injection1 .= $bits[$n]; }
                for (my $n=1; defined $bits[$n]; $n++) { last if $n > 1; $injection2 .= $bits[$n]; }                              
                $injection1 = '0' | $injection1;  
                $injection2 = '0' | $injection2;       
                splice @bits, 0, 2;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2 . $6;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 135)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMOV (immediate A2). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 136)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 136)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]" . $4 . "$random_bits[2]" . $6;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 136)) { $bin = $1 . $2 . "0" . $4 . "0" . $6; }
        if ((defined $options{u}) && ($skipped_ops_level < 136)) { $bin = $1 . $2 . "1" . $4 . $5 . $6; }         
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmov_cr2s_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0| 0| opc1| 0|    Vd     |    Rt     | 1  0  1  1| D| opc2| 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(11100..0........1011...1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 4 if $skipped_ops_level < 137;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "0000") {
                $instructions{'VMOV_CR2S_A1'}++;
                $skipped_ops_level = 137 if $skipped_ops_level < 138;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 4;
        $unconditional_storage += 4 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 137)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 3; $injection .= $bits[$n]; }
                $injection = '0000' | $injection;       
                splice @bits, 0, 4;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 136)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMOV (ARM core register to scalar). The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        }  
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 137)) { $extraction .= $3; }
		if ((defined $options{r}) && ($skipped_ops_level < 137)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]";
        }
        if ((defined $options{z}) && ($skipped_ops_level < 137)) { $bin = $1 . $2 . "0000"; }  
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_vmsr_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 1  1  1  0  1  1  1  0| 0  0  0  1|    Rt     | 1  0  1  0|(0)(0)(0) 1|(0)(0)(0)(0)
    my $bin = shift;
    if ($bin =~ /(....)(111011100001....1010)(...)(1)(....)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 7 if $skipped_ops_level < 138;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if (($3 ne "000") || ($5 ne "0000")) {
                $instructions{'VMSR_A1'}++;
                $skipped_ops_level = 138 if $skipped_ops_level < 139;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 7;
        $unconditional_storage += 7 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 138)) {
            my $injection1 = '';
            my $injection2 = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 2; $injection1 .= $bits[$n]; }
                for (my $n=3; defined $bits[$n]; $n++) { last if $n > 6; $injection2 .= $bits[$n]; }                              
                $injection1 = '000' | $injection1;  
                $injection2 = '0000' | $injection2;         
                splice @bits, 0, 7;                                     
            } else { $injection1 = $3; $injection2 = $5; }                                     
            $bin = $1 . $2 . $injection1 . $4 . $injection2;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 137)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of VMSR. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        } 
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 138)) { $extraction .= "$3$5"; } 
		if ((defined $options{r}) && ($skipped_ops_level < 138)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]" . $4 .
                "$random_bits[4]$random_bits[5]$random_bits[6]$random_bits[7]";
        } 
        if ((defined $options{z}) && ($skipped_ops_level < 138)) { $bin = $1 . $2 . "000" . $4 . "0000"; }
        if ((defined $options{u}) && ($skipped_ops_level < 138)) { $bin = $1 . $2 . "001" . $4 . $5; }                   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_wfe_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  1  1  0  0  1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  0  0  0  1  0
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(00000010)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 139;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'WFE_A1'}++;
                $skipped_ops_level = 139 if $skipped_ops_level < 140;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 139)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;         
                splice @bits, 0, 8;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 138)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of WFE. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        } 
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 139)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 139)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;
            }
        if ((defined $options{z}) && ($skipped_ops_level < 139)) { $bin = $1 . $2 . "11110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 139)) { $bin = $1 . $2 . "11100000" . $4; }   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_wfi_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  1  1  0  0  1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  0  0  0  1  1
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(00000011)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 140;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'WFI_A1'}++;
                $skipped_ops_level = 140 if $skipped_ops_level < 141;              
				$stegcount++;
			}
            return ($bin, 1);
        }
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 140)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;       
                splice @bits, 0, 8;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 139)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of WFI. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        } 
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 140)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 140)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 140)) { $bin = $1 . $2 . "11110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 140)) { $bin = $1 . $2 . "11100000" . $4; }    
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_yield_A1 {
#31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00
#   cond    | 0  0  1  1  0  0  1  0| 0  0  0  0|(1)(1)(1)(1)(0)(0)(0)(0) 0  0  0  0  0  0  0  1
    my $bin = shift;
    if ($bin =~ /(....)(001100100000)(........)(00000001)/) {
		if ($sizecheck eq 'yes') {
            $weird_ops += 8 if $skipped_ops_level < 141;
            return ($bin, 1);
        }
        if ($profile eq 'yes') {
            if ($3 ne "11110000") {
                $instructions{'YIELD_A1'}++;
                $skipped_ops_level = 141 if $skipped_ops_level < 142;              
				$stegcount++;
			}
            return ($bin, 1);
        } 
        $c_ops++;
        $storage += 8;
        $unconditional_storage += 8 if ($1 eq "1110");
        if ((defined $options{i}) && ($skipped_ops_level < 141)) {
            my $injection = '';
            if (@bits) {
                for (my $n=0; defined $bits[$n]; $n++) { last if $n > 7; $injection .= $bits[$n]; }
                $injection = '00000000' | $injection;        
                splice @bits, 0, 8;                                     
            } else { $injection = $3; }                                     
            $bin = $1 . $2 . $injection . $4;                                    
        }
        if ((defined $options{c}) && ($skipped_ops_level > 140)) {
            my $bit_ammount = @bits;
            $bit_ammount = $full_bit_size - $bit_ammount;
            if ($bit_ammount < 8) {
                print "\nWe have a problem: we are in our first $bit_ammount bytes encoding and skipping the\n" . 
                    "blacklisted instruction of YIELD. The extraction function would get\n" . 
                    "corrupt metadata for this very blacklist. Aborting.\n\n";
                    exit;
            }
        } 
		if (((defined $options{e}) || (defined $options{l})) && ($skipped_ops_level < 141)) { $extraction .= $3; } 
		if ((defined $options{r}) && ($skipped_ops_level < 141)) {
            get_random_bits();
            $bin = $1 . $2 . "$random_bits[1]$random_bits[2]$random_bits[3]$random_bits[4]" . 
                "$random_bits[5]$random_bits[6]$random_bits[7]$random_bits[8]" . $4;
        }
        if ((defined $options{z}) && ($skipped_ops_level < 141)) { $bin = $1 . $2 . "11110000" . $4; }
        if ((defined $options{u}) && ($skipped_ops_level < 141)) { $bin = $1 . $2 . "11100000" . $4; }   
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_AND_REG {
    my $bin = shift;
    if ($bin =~ /....0000000................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_AND_REGS {
    my $bin = shift;
    if ($bin =~ /....0000000.............0..1..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_EOR_REG {
    my $bin = shift;
    if ($bin =~ /....0000001................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_EOR_REGS {
    my $bin = shift;
    if ($bin =~ /....0000001.............0..1..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_MLA {
    my $bin = shift;
    if ($bin =~ /....0000001.............1001..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_SUB_REG {
    my $bin = shift;
    if ($bin =~ /....0000010................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STRH_IMM {
    my $bin = shift;
    if ($bin =~ /....000..1.0............1011..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDRD_IMM {
    my $bin = shift;
    if ($bin =~ /....000..1.0............1101..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STRD_IMM {
    my $bin = shift;
    if ($bin =~ /....000..1.0............1111..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDRH_IMM {
    my $bin = shift;
    if ($bin =~ /....000..1.1............1011..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDRSH_IMM {
    my $bin = shift;
    if ($bin =~ /....000..1.1............1111..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_RSB_REG {
    my $bin = shift;
    if ($bin =~ /....0000011................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ADD_REG {
    my $bin = shift;
    if ($bin =~ /....0000100................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ADC_REG {
    my $bin = shift;
    if ($bin =~ /....0000101................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_SBC_REG {
    my $bin = shift;
    if ($bin =~ /....0000110................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ORR_REG {
    my $bin = shift;
    if ($bin =~ /....0001100................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_AND_IMM {
    my $bin = shift;
    if ($bin =~ /....0010000...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_EOR_IMM {
    my $bin = shift;
    if ($bin =~ /....0010001...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_SUB_IMM {
    my $bin = shift;
    if ($bin =~ /....0010010...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_RSB_IMM {
    my $bin = shift;
    if ($bin =~ /....0010011...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ADD_IMM {
    my $bin = shift;
    if ($bin =~ /....0010100...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_MOV_IMM_A2 {
    my $bin = shift;
    if ($bin =~ /....00110000..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_MOVT {
    my $bin = shift;
    if ($bin =~ /....00110100..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_ORR_IMM {
    my $bin = shift;
    if ($bin =~ /....0011100...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_BIC_IMM {
    my $bin = shift;
    if ($bin =~ /....0011110...................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STR_IMM {
    my $bin = shift;
    if ($bin =~ /....010..0.0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STRB_IMM {
    my $bin = shift;
    if ($bin =~ /....010..1.0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDR_IMM {
    my $bin = shift;
    if ($bin =~ /....010..0.1..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDRB_IMM {
    my $bin = shift;
    if ($bin =~ /....010..1.1..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STR_REG {
    my $bin = shift;
    if ($bin =~ /....011..0.0...............0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STRB_REG {
    my $bin = shift;
    if ($bin =~ /....011..1.0...............0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDR_REG {
    my $bin = shift;
    if ($bin =~ /....011..0.1...............0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDRB_REG {
    my $bin = shift;
    if ($bin =~ /....011..1.1...............0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STMDA_STMED {
    my $bin = shift;
    if ($bin =~ /....100000.0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STM_STMIA_STMEA {
    my $bin = shift;
    if ($bin =~ /....100010.0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDM_LDMIA_LDMFD {
    my $bin = shift;
    if ($bin =~ /....100010.1..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STMDB_STMFD {
    my $bin = shift;
    if ($bin =~ /....100100.0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_B {
    my $bin = shift;
    if ($bin =~ /....1010......................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_BL_IMM {
    my $bin = shift;
    if ($bin =~ /....1011......................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_STC {
    my $bin = shift;
    if ($bin =~ /....110....0..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_LDC_IMM {
    my $bin = shift;
    if ($bin =~ /....110....1..................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_VPOP_A1 {
    my $bin = shift;
    if ($bin =~ /....11001.111101....1011......../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_CDP {
    my $bin = shift;
    if ($bin =~ /....1110...................0..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_MCR {
    my $bin = shift;
    if ($bin =~ /....1110...0...............1..../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

sub op_SVC {
    my $bin = shift;
    if ($bin =~ /....1111......................../) {
        return ($bin, 1);
    }
    return ($bin, 0);
}

main();
