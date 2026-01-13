package FugitiveGame::State;
use strict;
use warnings;
use FugitiveGame::Util qw(clamp);

sub new_game {
    my ($class, %args) = @_;
    my $name = $args{name} // 'Player';
    my $rng_mode = $args{rng_mode} // 'seeded';
    my $seed = $args{seed} // 12345;

    my $state = {
        player => {
            name => $name,
            day => 1,
            act => 1,
            slot => 'morning',
            location_id => 'apartment',
            meters => {
                reputation_underground => 20,
                reputation_media => 5,
                law_pressure => 10,
                stress => 20,
                isolation => 15,
                resources => 60,
                paranoia => 5,
                compliance => 55,
                sleep_debt => 10,
                equipment_integrity => 80,
                safehouse_stability => 70,
            },
            skills => {
                social_engineering => 4,
                telephony => 3,
                unix_systems => 3,
                tradecraft => 3,
            },
            identities => [
                { alias => 'Primary Alias', quality => 'medium', exposure => 0 },
            ],
            npcs => {},
            flags => {},
            rng => {
                mode => $rng_mode,
                seed => $seed,
            },
        },
        adversary => {
            awareness => 10,
            pattern_knowledge => 5,
            resource_commitment => 5,
            technical_focus => 5,
        },
        media => {
            demonization => 5,
            accuracy => 30,
            momentum => 5,
            simplification => 5,
            feedback_loop => 5,
        },
        surveillance => {
            paranoia => 5,
            false_positive_bias => 5,
            last_tap_signal_day => 0,
        },
        phones => {
            last_payphone_id => undef,
            payphone_reuse_streak => 0,
            last_call_hour_bucket => 'morning',
            routing_heat => 0,
            last_payphone_day => 0,
        },
        agencies => {
            fbi => { pressure => 10, coordination => 60, delay => 20 },
            telco_security => { pressure => 8, coordination => 55, delay => 25 },
            prosecutors => { pressure => 6, coordination => 50, delay => 30 },
            media => { pressure => 5, coordination => 45, delay => 15 },
        },
        patterns => {
            recent_actions => [],
            repetition_score => 0,
            habit_flags => {
                night_owl => 0,
                payphone_dependent => 0,
                stationary => 0,
            },
        },
        relationships => {},
        progress => {
            completed_campaign => 0,
            unlocked_chapter_mode => 0,
            ending_flags => [],
        },
        endgame => {
            stage => 0,
            stage_progress => 0,
        },
        story => {
            act => 1,
            chapter_id => 'opening_moves',
            chapter_day_index => 0,
        },
        daily => {
            exposure => 0,
            high_risk => 0,
            travel => 0,
            payphone => 0,
        },
        log_file => undef,
    };

    return $state;
}

sub ensure_npcs {
    my ($state, $npcs) = @_;
    for my $npc (@{$npcs || []}) {
        my $id = $npc->{id};
        next unless $id;
        $state->{player}{npcs}{$id} //= {
            trust => $npc->{base_trust} // 20,
            risk => $npc->{base_risk} // 10,
            last_contact_day => 0,
        };
        $state->{relationships}{$id} //= {
            trust => $npc->{base_trust} // 20,
            risk => $npc->{base_risk} // 10,
            closeness => $npc->{base_trust} // 20,
            drift => 0,
            last_contact_day => 0,
            last_outcome => 'neutral',
        };
    }
}

sub migrate {
    my ($state) = @_;
    $state->{player} //= {};
    $state->{player}{meters} //= {};
    $state->{player}{skills} //= {};
    $state->{player}{identities} //= [];
    $state->{player}{flags} //= {};
    $state->{player}{npcs} //= {};
    $state->{adversary} //= {};
    $state->{media} //= {};
    $state->{daily} //= {};
    $state->{surveillance} //= {};
    $state->{phones} //= {};
    $state->{agencies} //= {};
    $state->{patterns} //= {};
    $state->{relationships} //= {};
    $state->{progress} //= {};
    $state->{endgame} //= {};
    $state->{story} //= {};

    my $meters = $state->{player}{meters};
    $meters->{paranoia} //= 5;
    $meters->{compliance} //= 55;
    $meters->{sleep_debt} //= 10;
    $meters->{equipment_integrity} //= 80;
    $meters->{safehouse_stability} //= 70;

    $state->{media}{simplification} //= 5;
    $state->{media}{feedback_loop} //= 5;

    $state->{surveillance}{paranoia} //= $meters->{paranoia};
    $state->{surveillance}{false_positive_bias} //= 5;
    $state->{surveillance}{last_tap_signal_day} //= 0;

    $state->{phones}{last_payphone_id} //= undef;
    $state->{phones}{payphone_reuse_streak} //= 0;
    $state->{phones}{last_call_hour_bucket} //= 'morning';
    $state->{phones}{routing_heat} //= 0;
    $state->{phones}{last_payphone_day} //= 0;

    $state->{agencies}{fbi} //= { pressure => 10, coordination => 60, delay => 20 };
    $state->{agencies}{telco_security} //= { pressure => 8, coordination => 55, delay => 25 };
    $state->{agencies}{prosecutors} //= { pressure => 6, coordination => 50, delay => 30 };
    $state->{agencies}{media} //= { pressure => 5, coordination => 45, delay => 15 };

    $state->{patterns}{recent_actions} //= [];
    $state->{patterns}{repetition_score} //= 0;
    $state->{patterns}{habit_flags} //= {
        night_owl => 0,
        payphone_dependent => 0,
        stationary => 0,
    };

    $state->{progress}{completed_campaign} //= 0;
    $state->{progress}{unlocked_chapter_mode} //= 0;
    $state->{progress}{ending_flags} //= [];

    $state->{endgame}{stage} //= 0;
    $state->{endgame}{stage_progress} //= 0;

    $state->{story}{act} //= $state->{player}{act} // 1;
    $state->{story}{chapter_id} //= 'opening_moves';
    $state->{story}{chapter_day_index} //= 0;

    $state->{daily}{exposure} //= 0;
    $state->{daily}{high_risk} //= 0;
    $state->{daily}{travel} //= 0;
    $state->{daily}{payphone} //= 0;
    return $state;
}

sub clamp_state {
    my ($state) = @_;
    my $meters = $state->{player}{meters};
    for my $key (keys %{$meters}) {
        $meters->{$key} = clamp($meters->{$key}, 0, 100);
    }
    my $skills = $state->{player}{skills};
    for my $key (keys %{$skills}) {
        $skills->{$key} = clamp($skills->{$key}, 1, 10);
    }
    for my $identity (@{$state->{player}{identities}}) {
        $identity->{exposure} = clamp($identity->{exposure}, 0, 100);
    }
    for my $section (qw(adversary media)) {
        for my $key (keys %{$state->{$section}}) {
            $state->{$section}{$key} = clamp($state->{$section}{$key}, 0, 100);
        }
    }
    if ($state->{surveillance}) {
        for my $key (keys %{$state->{surveillance}}) {
            $state->{surveillance}{$key} = clamp($state->{surveillance}{$key}, 0, 100)
                if $key ne 'last_tap_signal_day';
        }
    }
    if ($state->{phones}) {
        $state->{phones}{payphone_reuse_streak} = clamp($state->{phones}{payphone_reuse_streak}, 0, 10);
        $state->{phones}{routing_heat} = clamp($state->{phones}{routing_heat}, 0, 100);
    }
    if ($state->{patterns}) {
        $state->{patterns}{repetition_score} = clamp($state->{patterns}{repetition_score}, 0, 100);
    }
    if ($state->{endgame}) {
        $state->{endgame}{stage} = clamp($state->{endgame}{stage}, 0, 4);
        $state->{endgame}{stage_progress} = clamp($state->{endgame}{stage_progress}, 0, 100);
    }
    if ($state->{agencies}) {
        for my $agency (values %{$state->{agencies}}) {
            for my $key (qw(pressure coordination delay)) {
                $agency->{$key} = clamp($agency->{$key}, 0, 100) if defined $agency->{$key};
            }
        }
    }
    if ($state->{player}{meters}{paranoia}) {
        $state->{surveillance}{paranoia} = $state->{player}{meters}{paranoia};
    }
}

1;
