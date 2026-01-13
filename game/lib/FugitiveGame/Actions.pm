package FugitiveGame::Actions;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp rng_int log_line);
use FugitiveGame::State;
use FugitiveGame::UI;
use FugitiveGame::Phones;
use FugitiveGame::Patterns;
use FugitiveGame::Relationships;

sub valid_actions {
    my ($state, $actions, $content) = @_;
    my $slot = $state->{player}{slot};
    my %npc_lookup = map { $_->{id} => $_ } @{$content->{npcs} || []};
    my @valid;
    for my $action (@{$actions || []}) {
        next unless grep { $_ eq $slot } @{$action->{valid_slots}};
        if (my $npc_id = $action->{npc_id}) {
            my $npc = $npc_lookup{$npc_id};
            next if $npc && $npc->{historical};
            next unless FugitiveGame::Relationships::is_available($state, $npc_id);
        }
        if (my $req = $action->{requirements}) {
            if (my $flag = $req->{flag}) {
                next unless $state->{player}{flags}{$flag};
            }
            if (my $min = $req->{min_meter}) {
                my ($key, $value) = %{$min};
                next unless $state->{player}{meters}{$key} >= $value;
            }
        }
        push @valid, $action;
    }
    return \@valid;
}

sub resolve_action {
    my ($state, $action, $content, $location) = @_;
    my $stress = $state->{player}{meters}{stress};
    my $risk = $action->{base_risk} + ($location->{risk_modifier} || 0) + int($stress / 5);

    my $skill_bonus = 0;
    if (my $weights = $action->{skill_weights}) {
        for my $skill (keys %{$weights}) {
            $skill_bonus += ($state->{player}{skills}{$skill} || 0) * $weights->{$skill};
        }
    }
    $skill_bonus = clamp($skill_bonus, 0, 25);
    my $effective_risk = clamp($risk - $skill_bonus, 0, 100);

    if ($action->{phone_action}) {
        $effective_risk += FugitiveGame::Phones::risk_modifier($state, $action);
    }
    $effective_risk += FugitiveGame::Patterns::risk_modifier($state, $action->{id}, $location->{id}, $state->{player}{slot});
    $effective_risk = clamp($effective_risk, 0, 100);

    my $roll = rng_int($state, 1, 100);

    my $outcome;
    if ($roll > $effective_risk) {
        $outcome = 'success';
    } elsif ($roll > $effective_risk - 15) {
        $outcome = 'partial';
    } else {
        $outcome = 'exposure';
    }

    my $outcome_def = $action->{outcomes}{$outcome};
    apply_effects($state, $outcome_def->{effects} || {});

    if ($action->{category} && $action->{category} eq 'move' && $action->{move_to}) {
        $state->{player}{location_id} = $action->{move_to};
    }
    if ($action->{phone_action}) {
        FugitiveGame::Phones::update_after_call($state, $location->{id}, $state->{player}{slot});
    }
    if (my $npc_id = $action->{npc_id}) {
        FugitiveGame::Relationships::record_contact($state, $npc_id, $outcome);
    }
    FugitiveGame::Patterns::update_after_action($state, $action->{id}, $location->{id}, $state->{player}{slot});

    my $effect_summary = _summarize_effects($outcome_def->{effects} || {});
    log_line($state, "Action: $action->{id} act=$state->{story}{act} chapter=$state->{story}{chapter_id} roll=$roll risk=$effective_risk outcome=$outcome effects={$effect_summary}");

    return {
        outcome => $outcome,
        roll => $roll,
        effective_risk => $effective_risk,
        text => $outcome_def->{text} || '',
    };
}

sub apply_effects {
    my ($state, $effects) = @_;
    for my $meter (keys %{$effects->{meters} || {}}) {
        $state->{player}{meters}{$meter} += $effects->{meters}{$meter};
    }
    for my $skill (keys %{$effects->{skills} || {}}) {
        $state->{player}{skills}{$skill} += $effects->{skills}{$skill};
    }
    if (my $flags = $effects->{flags}) {
        for my $flag (keys %{$flags}) {
            $state->{player}{flags}{$flag} = $flags->{$flag};
        }
    }
    if (my $npc = $effects->{npc}) {
        my $id = $npc->{id};
        if ($id && $state->{player}{npcs}{$id}) {
            $state->{player}{npcs}{$id}{trust} += $npc->{trust} if defined $npc->{trust};
            $state->{player}{npcs}{$id}{risk} += $npc->{risk} if defined $npc->{risk};
            $state->{player}{npcs}{$id}{last_contact_day} = $state->{player}{day};
        }
    }
    if (my $identity = $effects->{add_identity}) {
        push @{$state->{player}{identities}}, {
            alias => $identity->{alias},
            quality => $identity->{quality},
            exposure => 0,
        };
        $state->{player}{flags}{identity_burned} = 0;
    }
    if (defined $effects->{identity_exposure}) {
        if (my $current = $state->{player}{identities}[0]) {
            $current->{exposure} += $effects->{identity_exposure};
        }
    }
    if (defined $effects->{daily_exposure}) {
        $state->{daily}{exposure} += $effects->{daily_exposure};
    }
    if (defined $effects->{daily_high_risk}) {
        $state->{daily}{high_risk} += $effects->{daily_high_risk};
    }
    if (defined $effects->{daily_travel}) {
        $state->{daily}{travel} += $effects->{daily_travel};
    }
    if (defined $effects->{daily_payphone}) {
        $state->{daily}{payphone} += $effects->{daily_payphone};
    }

    FugitiveGame::State::clamp_state($state);
}

sub forced_identity_choice {
    my ($state) = @_;
    return unless $state->{player}{flags}{identity_burned};
    return if $state->{player}{flags}{identity_burned_resolved_day} == $state->{player}{day};

    print "\nA primary identity has burned. Options: acquire a new burner or accept heavy penalties.\n";
    my $choice = FugitiveGame::UI::prompt("Type 'acquire' or 'accept': ");
    if ($choice =~ /^acquire/i) {
        if ($state->{player}{meters}{resources} < 20) {
            print "Not enough resources. You absorb the penalties.\n";
            apply_effects($state, { meters => { law_pressure => 10, stress => 10 }, flags => { identity_burned => 1 } });
        } else {
            apply_effects($state, { meters => { resources => -20 }, add_identity => { alias => 'Burner ID', quality => 'low' }, flags => { identity_burned => 0 } });
            print "You acquire a burner identity.\n";
        }
    } else {
        apply_effects($state, { meters => { law_pressure => 10, stress => 10 }, flags => { identity_burned => 1 } });
        print "You keep moving with a burned identity.\n";
    }
    $state->{player}{flags}{identity_burned_resolved_day} = $state->{player}{day};
}

sub _summarize_effects {
    my ($effects) = @_;
    my @parts;
    if (my $meters = $effects->{meters}) {
        for my $key (sort keys %{$meters}) {
            push @parts, "meter:$key=$meters->{$key}";
        }
    }
    if (my $skills = $effects->{skills}) {
        for my $key (sort keys %{$skills}) {
            push @parts, "skill:$key=$skills->{$key}";
        }
    }
    if (defined $effects->{daily_exposure}) {
        push @parts, "daily_exposure=$effects->{daily_exposure}";
    }
    if (defined $effects->{daily_high_risk}) {
        push @parts, "daily_high_risk=$effects->{daily_high_risk}";
    }
    if (defined $effects->{daily_travel}) {
        push @parts, "daily_travel=$effects->{daily_travel}";
    }
    if (defined $effects->{daily_payphone}) {
        push @parts, "daily_payphone=$effects->{daily_payphone}";
    }
    if (my $npc = $effects->{npc}) {
        push @parts, "npc:$npc->{id}";
    }
    if (my $identity = $effects->{add_identity}) {
        push @parts, "add_identity=$identity->{alias}";
    }
    return join(',', @parts) || 'none';
}

1;
