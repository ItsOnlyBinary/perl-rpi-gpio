package RPi::GPIO;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new {
    my($class, %parameters) = @_;

    my $self = bless({EXPORTED => {}}, ref ($class) || $class);

    #note the pin numbers start at 1 and arrays start at 0
    $self->{PIN}  = [undef, undef, undef, 0, undef, 1, undef, 4, 14, undef, 15, 17, 18, 21, undef, 22, 23, undef, 24, 10, undef, 9, 25, 11, 8, undef, 7];
    $self->{BCM}  = [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25];
    $self->{MODE} = 'PIN';
    $self->{PATH} = '/sys/class/gpio/';

    if(defined($parameters{PATH})) {
	if(-e $parameters{PATH} && -d $parameters{PATH}) {
	    $self->{PATH} = $parameters{PATH};
	    unless($self->{PATH} =~ m/\/\z/) {
		$self->{PATH} .= '/';
	    }
	}
	else {
	    warn 'Invalid PATH parameter';
	}
    }

    if(defined($parameters{MODE})) {
	if($parameters{MODE} =~ m/^(PIN|BCM)\z/i ) {
	    $self->{MODE} = uc($parameters{MODE});
	}
	else {
	    warn "Invalid MODE parameter";
	}
    }

    if(defined($parameters{PIN})) {
	if(ref $parameters{PIN} eq 'ARRAY') {
	    my $pass = 1;
	    foreach(@{$parameters{PIN}}) {
		unless(!defined $_ || $_ =~ m/^\d+\z/) {
		    warn 'Invalid PIN parameter';
		    $pass--;
		}
	    }
	    $self->{PIN} = $parameters{PIN} if($pass);
	}
	else {
	    warn "Invalid PIN parameter"
	}
    }

    if(defined($parameters{BCM})) {
	if(ref $parameters{BCM} eq 'ARRAY') {
	    my $pass = 1;
	    foreach(@{$parameters{BCM}}) {
		unless(defined $_ && $_ =~ m/^\d+\z/) {
		    warn 'Invalid BCM parameter';
		    $pass--;
		}
	    }
	    $self->{BCM} = $parameters{BCM} if($pass);
	}
	else {
	    warn "Invalid BCM parameter"
	}
    }

    return $self;
}

sub setup {
    my($self, $channel, $direction) = @_;

    #check $channel
    $channel = $self->validate($channel);
    unless(defined($channel)) {
	warn 'Invalid channel used for GPIO setup';
	return 0;
    }

    #check $direction
    unless(defined($direction) && $direction =~ m/^(IN|OUT)\z/i) {
	warn 'Invalid direction used for GPIO setup';
	return 0;
    }
    $direction = lc($direction);

    #unexport if gpio definition exists
    if(-e $self->{PATH}.'gpio'.$channel) {
	$self->remove($channel);
    }

    #export gpio definition
    if(open my $fh, '>', $self->{PATH}.'export') {
	print $fh $channel;
	close $fh;
    }
    else {
	warn 'setup error opening export';
	return 0;
    }

    #set gpio direction
    if(open my $fh, '>', $self->{PATH}.'gpio'.$channel.'/direction') {
	print $fh $direction;
	close $fh;
    }
    else {
	warn 'setup error opening gpio direction';
	return 0;
    }

    #one last sanity check
    unless(-e $self->{PATH}.'gpio'.$channel) {
	warn 'setup did not manage to configure the gpio channel';
	return 0;
    }

    $self->{EXPORTED}{$channel} = $direction;
    return 1;
}

sub output {
    my($self, $channel, $value) = @_;

    #check $channel
    $channel = $self->validate($channel);
    unless(defined($channel)) {
	warn 'Invalid channel used for GPIO output';
	return 0;
    }

    #check $channel is exported and set to output mode
    unless(defined($self->{EXPORTED}{$channel}) && $self->{EXPORTED}{$channel} eq 'out') {
	warn 'Tried to output on invalid channel';
	return 0;
    }

    #validate output
    $value = (defined($value) && $value)? 1 : 0;

    #set the $value on gpio channel
    if(open my $fh, '>', $self->{PATH}.'gpio'.$channel.'/value') {
	print $fh $value;
	close $fh;
    }
    else {
	warn 'output error opening gpio value';
	return 0;
    }

    return 1;
}

sub input {
    my($self, $channel) = @_;

    #check $channel
    $channel = $self->validate($channel);
    unless(defined($channel)) {
	warn 'Invalid channel used for GPIO setup';
	return undef;
    }

    #check $channel is exported and set to input mode
    unless(defined($self->{EXPORTED}{$channel}) && $self->{EXPORTED}{$channel} eq 'in') {
	warn 'Tried to input on invalid channel';
	return undef;
    }

    if(open my $fh, '<', $self->{PATH}.'gpio'.$channel.'/value') {
	my $value = <$fh>;
	close $fh;
	return $value;
    }
    else {
	warn 'input unable to open gpio value';
	return undef;
    }
}

sub validate {
    my($self, $channel) = @_;
    unless(defined($channel) && $channel =~ /^\d+\z/) {
        warn 'The channel sent was not an integer';
        return undef;
    }

    if($self->{MODE} eq 'BCM') {
        unless(grep $_ == $channel, @{$self->{BCM}}) {
            warn 'The BCM channel sent is invalid on a Raspberry Pi';
            return undef;
        }
    }
    else {
        $channel = $self->{PIN}[$channel];
        unless(defined($channel)) {
            warn 'The PIN channel sent is invalid on a Raspberry Pi';
            return undef;
        }
    }

    return $channel;
}

sub remove {
    my($self, $channel) = @_;

    if(defined($channel) && $channel =~ m/^\d+\z/) {
	#check $channel
	$channel = $self->validate($channel);
	unless(defined($channel)) {
	    warn 'Invalid remove parameter';
	    return 0;
	}
	
	unless(-e $self->{PATH}.'gpio'.$channel) {
	    warn 'Invalid remove channel';
	    return 0;
	}

	if(open my $fh, '>', $self->{PATH}.'unexport') {
	    print $fh $channel;
	    close $fh;
	}
	else {
	    warn 'Erorr remove could not open unexport';
	    return 0;
	}

	unless(!-e $self->{PATH}.'gpio'.$channel) {
	    warn 'Error remove could not unexport gpio'.$channel;
	    return 0;
	}

	return 1;
    }
    elsif(defined($channel) && $channel =~ m/^ALL\z/i) {
	foreach(@{keys $self->{EXPORTED}}) {
	    if($self->remove($_)){
		delete $self->{EXPORTED}{$_};
	    }
	    else {
		warn 'Error remove could not unexport gpio'.$_
	    }
	}
	return %{$self->{EXPORTED}} ? 0 : 1;
    }
    else {
	warn 'Invalid remove parameter';
	return 0;
    }
}

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!


=head1 NAME

RPi::GPIO - GPIO Access for Raspberry Pi

=head1 SYNOPSIS

    use RPi::GPIO;
    my $gpio = RPi::GPIO->new(MODE => 'PIN');
    $gpio->setup(11,'INPUT');
    $gpio->setup(12,'OUTPUT');
    my $value = $gpio->input(11);
    print "INPUT 11 = $value\n";
    $gpio->setup(12, $value);


=head1 DESCRIPTION

Simple use of Raspberry Pi's GPIO pins


=head1 USAGE

=head2 new(MODE => $mode, PIN => @pin, BCM => @bcm)
    Create new RPi:GPIO instance.
    
    PATH - Path to gpio
    default: /sys/class/gpio/
    
    MODE - GPIO Access Method:
    PIN: Raspberry Pi's GPIO pin numbers.
    BCM: Raspberry Pi's Broadcom GPIO designation.

    PIN - Set Raspberry Pi PIN -> BCM map
    [undef, undef, undef, 0, undef, 1, undef, 4, 14, undef, 15, 17, 18, 21, undef, 22, 23, undef, 24, 10, undef, 9, 25, 11, 8, undef, 7]
    NOTE: the first undef is for array[0] as the RPi starts at PIN 1

    BCM - List of BCM GPIO designations
    [0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25]

    returns: $self


=head2 setup($channel, $direction)
    Register a GPIO channel and set its direction

    $channel = PIN or BCM designation depending on mode
    $direction = IN or OUT
    returns: 1 success, 0 fail


=head2 input($channel)
    Get GPIO's current state

    $channel = PIN or BCM designation depending on mode
    returns: 0,1 or undef if failed


=head2 output($channel, $value)
    Set GPIO's current state

    $channel = PIN or BCM designation depending on mode
    $value = 0 or 1
    returns: 1 success, 0 fail

=head2 remove($channel)
    remove a gpio channel
    
    $channel = PIN or BCM designation depending on mode
    if $channel = 'ALL' it will remove all

=head1 BUGS

If there are none I will be surprised and always room for improvement

=head1 SUPPORT

#raspberrypi on FreeNode IRC

=head1 AUTHOR

    NucWin
    nucwin@gmail.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).
https://github.com/nucwin/rpi-gpio

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

