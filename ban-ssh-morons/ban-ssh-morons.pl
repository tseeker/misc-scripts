#!/usr/bin/perl

use strict;

use Sys::Syslog;
use POSIX;

our $IDIOT_FILE = '/var/cache/ssh-morons';
our $AUTH_LOG = '/var/log/auth.log';
our $MAX_FAIL = 5;
our $BL_RULE = 'BLACKLIST';


sub writeLog
{
        openlog( 'ban-ssh-morons' , 'nofatal,pid,perror' , 'LOCAL0' );
        syslog( @_ );
        closelog( );
}


sub checkForIdiots
{
	my $MAX_FAIL = 5;
	my $fn = shift;

	my %idiots = ( );
	if ( open( my $fh , $IDIOT_FILE ) ) {
		while ( my $idiot = <$fh> ) {
			chop $idiot;
			$idiots{ $idiot } = $MAX_FAIL;
		}
		close $fh;
	}

	$fn = $AUTH_LOG unless defined $fn;

	my $foundNewIdiots = 0;
	open( my $fh , '<' , $fn )
		or die "couldn't open $fn\n";
	while ( my $line = <$fh> ) {
		chop $line;
		next unless $line =~ /sshd.*Failed password for( invalid user)? .* from (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) port.*/;
		my $newIdiot = $2;
		next if ( defined $idiots{ $newIdiot } && $idiots{ $newIdiot } >= $MAX_FAIL );
		$idiots{ $newIdiot } = 0 unless defined $idiots{ $newIdiot };
		$idiots{ $newIdiot } ++;
		if ( $idiots{ $newIdiot } >= $MAX_FAIL ) {
			writeLog( 'notice' , 'Adding %s to SSH blacklist' , $newIdiot );
			$foundNewIdiots = 1;
		}
	}
	close $fh;

	writeLog( 'info' , 'Blacklist now contains %d entries' , scalar( keys( %idiots ) ) )
		if $foundNewIdiots;

	my @commands = ( );
	open( my $fh , '>' . $IDIOT_FILE );
	foreach my $cretin ( keys %idiots ) {
		next unless $idiots{ $cretin } >= $MAX_FAIL;
		print $fh "$cretin\n";
		push @commands , "iptables -A $BL_RULE -s $cretin -j DROP";
	}
	close $fh;

	system( 'iptables -F ' . $BL_RULE );
	foreach my $cmd ( @commands ) {
		system( $cmd );
	}
}


sub mainLoop
{
	my $mustExit = 0;
	my $sigHandler = sub {
		$mustExit = 1;
	};

	local $SIG{TERM} = $sigHandler;
	local $SIG{INT} = $sigHandler;

	my $signals = new POSIX::SigSet( &POSIX::SIGINT , &POSIX::SIGTERM , &POSIX::SIGHUP );

	writeLog( 'info' , 'SSH blacklist updater starting' );
	while ( !$mustExit ) {
		sigprocmask( SIG_BLOCK , $signals , new POSIX::SigSet( ) );
		checkForIdiots;
		sigprocmask( SIG_UNBLOCK , $signals , new POSIX::SigSet( ) );
		sleep 60;
	}
	writeLog( 'info' , 'SSH blacklist updater terminating' );
}


sub runDaemon
{
	# Fork to background
	exit 0 if fork( );
	close( STDIN );
	close( STDOUT );
	close( STDERR );
	open( STDIN , "/dev/null" );
	open( STDOUT , ">/dev/null" );
	open( STDERR , ">/dev/null" );

	# Write PID file
	my $pidFile = '/var/run/ban-ssh-morons.pid';
	if ( -e $pidFile ) {
		writeLog( 'crit' , 'PID file %s exists; exiting' , $pidFile );
		die;
	}
	if ( open( my $f , '>' , $pidFile ) ) {
		print $f "$$\n";
		close $f;
	} else {
		writeLog( 'crit' , 'unable to create PID file %s' , $pidFile );
		die;
	}

	# Run main loop
	mainLoop;

	# Delete PID file
	unlink $pidFile;
}


if ( @ARGV ) {
	checkForIdiots( $ARGV[0] );
} else {
	runDaemon;
}
