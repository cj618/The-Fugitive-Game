package FugitiveGame::Save;
use strict;
use warnings;
use JSON::PP;
use File::Spec;
use File::Temp qw(tempfile);
use FugitiveGame::Util qw(timestamp build_path);
use FugitiveGame::State;

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
    my $state = JSON::PP->new->decode($json);
    FugitiveGame::State::migrate($state);
    FugitiveGame::State::clamp_state($state);
    return $state;
}

sub list_saves {
    my ($dir) = @_;
    opendir my $dh, $dir or return [];
    my @files = grep { /\.json$/ && $_ ne 'progress.json' } readdir $dh;
    closedir $dh;
    @files = sort { (stat(build_path($dir, $b)))[9] <=> (stat(build_path($dir, $a)))[9] } @files;
    return [map { build_path($dir, $_) } @files];
}

sub save_progress {
    my ($progress, $dir) = @_;
    my $path = build_path($dir, 'progress.json');
    my $json = JSON::PP->new->canonical->pretty->encode($progress);
    open my $fh, '>', $path or die "Failed to write progress: $!";
    print {$fh} $json;
    close $fh;
    return $path;
}

sub load_progress {
    my ($dir) = @_;
    my $path = build_path($dir, 'progress.json');
    return { unlocked_chapter_mode => 0 } unless -e $path;
    open my $fh, '<', $path or return { unlocked_chapter_mode => 0 };
    local $/;
    my $json = <$fh>;
    close $fh;
    return JSON::PP->new->decode($json);
}

1;
