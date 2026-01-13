#!/usr/bin/perl

#
# Copyright (c) 2026, C Jervis - chrisxjervis@gmail.com
#
# Licensing information, see: LICENSE file for details.
#
#
# EARLY DEVELOPMENT VERSION
#
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FugitiveGame::State;
use FugitiveGame::Save;
use FugitiveGame::Content;
use FugitiveGame::Engine;
use FugitiveGame::UI;
use FugitiveGame::Scenarios;
use FugitiveGame::Util qw(timestamp build_path);

my $data_dir = build_path($FindBin::Bin, 'data');
my $save_dir = build_path($FindBin::Bin, 'saves');
my $log_dir = build_path($FindBin::Bin, 'logs');

my $content = FugitiveGame::Content::load_all($data_dir);

while (1) {
    my $progress = FugitiveGame::Save::load_progress($save_dir);
    print "\n=== The Fugitive Game (Alpha) ===\n";
    if ($progress->{unlocked_chapter_mode}) {
        print "1. New Game\n2. Load Game\n3. Chapter Mode\n4. Quit\n";
    } else {
        print "1. New Game\n2. Load Game\n3. Quit\n";
    }
    my $choice = FugitiveGame::UI::prompt('> ');

    if ($choice eq '1') {
        my $name = FugitiveGame::UI::prompt("Codename: ");
        my $rng_choice = FugitiveGame::UI::prompt("RNG mode (A) seeded / (B) random: ");
        my $mode = $rng_choice =~ /^b/i ? 'random' : 'seeded';
        my $seed = $mode eq 'random' ? time + $$ : 12345;
        my $state = FugitiveGame::State->new_game(name => $name, rng_mode => $mode, seed => $seed);
        $state->{log_file} = build_path($log_dir, 'run_' . timestamp() . '.log');

        FugitiveGame::Engine::run($state, $content, $save_dir);
        next;
    }

    if ($choice eq '2') {
        my $saves = FugitiveGame::Save::list_saves($save_dir);
        if (!@$saves) {
            print "No saves found.\n";
            next;
        }
        my @labels = map { $_ } @$saves;
        my $pick = FugitiveGame::UI::menu_choice('Select a save:', \@labels);
        my $path = $saves->[$pick];
        my $state = FugitiveGame::Save::load_state($path);
        $state->{log_file} = build_path($log_dir, 'run_' . timestamp() . '.log');
        FugitiveGame::Engine::run($state, $content, $save_dir);
        next;
    }

    if ($progress->{unlocked_chapter_mode} && $choice eq '3') {
        my $scenarios = FugitiveGame::Scenarios::available_scenarios({ progress => $progress }, $content->{scenarios});
        my @titles = map { $_->{title} } @$scenarios;
        my $pick = FugitiveGame::UI::menu_choice('Select a scenario:', \@titles);
        my $scenario = $scenarios->[$pick];
        my $state = FugitiveGame::State->new_game(name => 'Scenario', rng_mode => 'seeded', seed => 12345);
        $state->{progress} = $progress;
        $state = FugitiveGame::Scenarios::build_state_for_scenario($state, $scenario);
        $state->{log_file} = build_path($log_dir, 'run_' . timestamp() . '.log');
        FugitiveGame::Engine::run($state, $content, $save_dir);
        next;
    }

    if (!$progress->{unlocked_chapter_mode} && $choice eq '3') {
        last;
    }

    if ($progress->{unlocked_chapter_mode} && $choice eq '4') {
        last;
    }

    print "Invalid choice.\n";
}
