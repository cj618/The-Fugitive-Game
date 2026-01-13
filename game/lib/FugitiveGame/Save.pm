package FugitiveGame::Save;
use strict;
use warnings;
use JSON::PP;
use File::Spec;
use File::Temp qw(tempfile);
use FugitiveGame::Util qw(timestamp build_path);

sub save_state {
    my ($state, $dir) = @_;
    my $name = $state->{player}{name} || 'player';
    my $stamp = timestamp();
    my $filename = "$name\_$stamp.json";
    my $path = build_path($dir, $filename);

    my $json = JSON::PP->new->canonical->pretty->encode($state);
    my ($fh, $temp) = tempfile('saveXXXX', DIR => $dir, UNLINK => 0);
    print {$fh} $json;
    close $fh;
    rename $temp, $path or die "Failed to write save: $!";
    return $path;
}

sub load_state {
    my ($path) = @_;
    open my $fh, '<', $path or die "Failed to open save: $!";
    local $/;
    my $json = <$fh>;
    close $fh;
    return JSON::PP->new->decode($json);
}

sub list_saves {
    my ($dir) = @_;
    opendir my $dh, $dir or return [];
    my @files = grep { /\.json$/ } readdir $dh;
    closedir $dh;
    @files = sort { (stat(build_path($dir, $b)))[9] <=> (stat(build_path($dir, $a)))[9] } @files;
    return [map { build_path($dir, $_) } @files];
}

1;
