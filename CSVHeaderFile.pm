package IO::CSVHeaderFile;
# $Id: CSVHeaderFile.pm,v 1.1.1.1 2002/08/23 13:36:21 vasek Exp $

use strict;
use Text::CSV_XS;
use IO::File;
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;

@ISA = qw(IO::File Exporter);

@EXPORT = qw(
        
);

$VERSION = '0.01';

sub open {
	my $self = shift;
	my $args = {}; $args = pop @_ if ref($_[$#_]) eq 'HASH';
	$args->{eol}|= "\n";
	my $csv = Text::CSV_XS->new($args);
	my $mode;
	if(@_ > 1){
		croak 'usage: $fh->open(FILENAME [ ,< > >> ][,CSVOPT])' if $_[2] =~ /^\d+$/;
		$mode = IO::Handle::_open_mode_string($_[1]);
	}else{
		$mode = $_[0];
		$mode =~ s/^(\+?<|>>?)(.*)$/$1/ 
			or croak 'usage: $fh->open(FILENAME [,< > >> ][,CSVOPT])';
	}
	my ($fh, $firstline);
	if($mode =~ /^<$/){
		$fh = $self->SUPER::open( @_ ) or return;
		unless($args->{noheader}){
			unless( $firstline = $self->getline ){
				$self->close;
				return;
			}
			$csv->parse($firstline) and $args->{col} = [ $csv->fields ]
				unless $args->{col};
		}
		unless(${*$self}{io_csvheaderfile_cols} = $args->{col}){
			$self->close;
			croak "IO::CSVHeaderFile: Can't find the column names in '$_[0]'";
			return;
		}	
	}elsif( $mode =~ /^>>?$/){
		unless(${*$self}{io_csvheaderfile_cols} = $args->{col}){
			$self->close;
			croak "IO::CSVHeaderFile: Can't find the column names in '$_[0]'";
			return;
		}
		$fh = $self->SUPER::open( @_ ) or return;
		$csv->print($self, $args->{col})
			unless $mode =~ /^>>$/ or $args->{noheader};
	}else{
		croak "IO::CSVHeaderFile: Invalid mode '$mode'";
		return;
	}
	${*$self}{io_csvheaderfile_csv} = $csv;
	$fh
}

sub csv_read{
	my $self = shift;
	my $line = $self->getline() or return;
	${*$self}{io_csvheaderfile_csv}->parse($line) or return {};
	my @cols = ${*$self}{io_csvheaderfile_csv}->fields;
	my %result = ();
	my $colnames = ${*$self}{io_csvheaderfile_cols};
	for(my $i = 0; $i < @$colnames; $i++){
		$result{$colnames->[$i]} = $cols[$i];
	}
	\%result
}

sub csv_print{
	my ($self, $rec) = @_;
	return undef unless $rec and ref($rec) eq 'HASH';
	my @columns = ();
	push( @columns, $rec->{$_})
		foreach (@{${*$self}{io_csvheaderfile_cols}});
	${*$self}{io_csvheaderfile_csv}->print($self,\@columns);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

IO::CVSHF - Perl extension for CSV Files 

=head1 SYNOPSIS

  # to read ...
  use IO::CSVHeaderFile;
  my $csv = IO::CSVHeaderFile->new( "< $filename" );
  my $data;
  while($hash = $csv->csv_read ){
  	print "$data->{ColHeaderTitle}\n";
  }
  
  # to write ...
  use IO::CSVHeaderFile;
  my $csv = IO::CSVHeaderFile->new( "> $filename" , 
  	{col => ['ColHeaderTitle'], noheaders => 1} );
  my $data;
  while($hash = $csv->csv_read ){
  	print "$data->{ColHeaderTitle}\n";
  }

=head1 DESCRIPTION

Read from and write to csv file.


=head2 EXPORT

None by default.

=head2 FUNCTIONS

=over 4

=item csv_print RECORD

Store the C<RECORD> (hash reference) into file

=item csv_read

Return the next record (hash reference) from the file or C<undef> if C<eof>;

=cut

=head1 AUTHOR

Vasek Balcar, E<lt>vasek@ti.czE<gt>

=head1 SEE ALSO

L<IO::File>, L<IO::Handle>, L<perl>.

=cut
