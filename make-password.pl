#!/usr/bin/perl

use strict;

sub genPassword
{
	my $len = shift;
	my $simple = shift;
        my @characters;
	@characters = ( 'A' .. 'Z' , 'a' .. 'z' , '0' .. '9' );
	unless ( $simple ) {
		@characters = ( @characters ,
			'!' , '=' , '+' , '-' , '/' , '*' , '.' ,
			'(' , ')' , '[' , ']' , '{' , '}' );
	}
	while ( @characters < $len * 2 ) {
		@characters = ( @characters , @characters );
	}
        for ( my $i = 0 ; $i < 10 ; $i ++ ) {
                @characters = sort { int( rand() * 3 ) - 1 } @characters;
        }
        return join( '' , @characters[ 0 .. ( $len - 1 ) ] );
}

my $mlen = 13;
my $simple = 0;
if ( $ARGV[0] eq 'simple' ) {
	shift @ARGV;
	$simple = 1;
}
$mlen = int( $ARGV[0] ) if $ARGV[0];
print genPassword( $mlen , $simple ) . "\n";
