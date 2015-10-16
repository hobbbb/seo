package seo;
use Dancer ':syntax';
use Data::Dumper;
use Spreadsheet::Read;
use Lingua::Stem::Snowball;

our $VERSION = '0.1';

get '/seo' => sub {
    template 'index';
};

post '/seo' => sub {
    my $file = request->upload('file');

    my $book = ReadData($file->{tempname})->[1];
    my $stemmer = Lingua::Stem::Snowball->new(lang => 'ru', encoding => 'UTF-8');

    our ($res, $hash, $uniq);

    my ($multi, $singl);
    for my $row ($book->{minrow} .. $book->{maxrow}) {
        my $text = $book->{"A$row"};
        my $freq = $book->{"B$row"} || 0;
        next if $text =~ /^#/;

        my $flag = utf8::is_utf8($text);
        unless ($flag) {
            utf8::decode($text);
        }

        my @stem = split /\s+/, $text;
        $stemmer->stem_in_place(\@stem);

        if (scalar @stem > 1) {
            for my $s (@stem) {
                $multi->{$s}{row}{$row} = 1;
                $multi->{$s}{cnt}++;
            }
        }
        else {
            $singl->{$stem[0]}{row}{$row} = 1;
            $singl->{$stem[0]}{cnt}++;
        }

        $hash->{$row} = {
            text => $text,
            freq => $freq,
            stem => \@stem,
        };
    }

    # my (%hh, $i);
    # for (sort { $multi->{$b}{cnt} <=> $multi->{$a}{cnt}} keys %$multi) {
    #     $i++;
    #     $hh{$i} = $multi->{$_}{row};
    # }

    # for my $i (2 .. scalar keys %hh) {
    #     my @a = ();
    #     for my $row (keys %{$hh{$i}}) {
    #         if (grep(/^$row$/, keys %{$hh{1}})) {
    #             push @a, { $hash->{$row}{text} => $hash->{$row}{freq} };
    #             delete $hh{1}{$row};
    #             delete $hh{$i}{$row};
    #         }
    #     }
    #     push @$res, {
    #         name => "g$i",
    #         word => \@a,
    #     };
    # }

    our $arr;
    for (sort { $multi->{$b}{cnt} <=> $multi->{$a}{cnt}} keys %$multi) {
       push @$arr, $multi->{$_}{row};
    }

    bas();

    sub bas {
        unless (scalar keys %{$arr->[0]}) {
            shift @$arr;
            bas();
        }

        for my $i (1 .. scalar @$arr) {
           my @a = ();
           for my $row (keys %{$arr->[$i]}) {
               if (grep(/^$row$/, keys %{$arr->[0]})) {
                    push @a, { $hash->{$row}{text} => $hash->{$row}{freq} };
                    delete $arr->[$i]{$row};

                    delete $arr->[0]{$row};
                    unless (scalar keys %{$arr->[0]}) {
                        shift @$arr;
                        bas();
                    }
               }
           }
           if (@a) {
               push @$res, {
                   name => "group $i",
                   word => \@a,
               };
           }
        }
    }

    # die Dumper $arr;


    #push @$res, func($multi);
    #push @$res, func($singl);

    sub func {
        my $h = shift;

        my @ret = ();
        for my $w (sort { $h->{$b}{cnt} <=> $h->{$a}{cnt}} keys %$h) {
           # print "$w - " . Dumper $h->{$w};
           # last;
            my @arr;
            for my $row (sort keys %{$h->{$w}{row}}) {
                next if exists $uniq->{$row};
                push @arr, { $hash->{$row}{text} => $hash->{$row}{freq} };
                $uniq->{$row} = 1;
            }
            push @ret, {
                name => $w,
                word => \@arr,
            };
        }
        return @ret;
    }

    return template 'index' => {
        group => $res,
    };
};

post '/seo_old' => sub {
    my $file = request->upload('file');

    my $res;
    my $book = ReadData($file->{tempname})->[1];
=c
    my %hash;
    for my $row ($book->{minrow} .. $book->{maxrow}) {
        # my $text = decode('utf8', $book->{"A$row"});
        my $text = $book->{"A$row"};
        $hash{$row} = {
            text    => $text,
            matches => {},
            cnt     => 0,
        };
    }

    my %h = %hash;

    my ($i, %group) = (1, ());
    for my $n (keys %h) {
        next unless exists $h{$n};

        push @{$group{$i}{matches}}, $n;
        $group{$i}{cnt}++;
        my $cur = delete $h{$n};

        my @word = split /\s+/, $cur->{text};
        # print '--' . join(',', @word) . "\n" if $i == 27;
        for my $nn (keys %h) {
            my @tmp = split /\s+/, $h{$nn}{text};
            my $cnt = 0;
            for my $w (@word) {
                $cnt++ if grep(/^$w$/, @tmp);
            }

            if ($cnt >= 2) {
                # print join(',', @tmp) . "\n" if $i == 27;
                push @{$group{$i}{matches}}, $nn;
                $group{$i}{cnt}++;
                delete $h{$nn};
            }
        }

        $i++;
    }

    $i = 1;
    for my $k (sort { $group{$b}{cnt} <=> $group{$a}{cnt}} keys %group) {
        my @arr;
        for my $n (@{$group{$k}{matches}}) {
            push @arr, $hash{$n}{text};
        }
        push @$res, {
            name => "Группа $i",
            word => \@arr,
        };
        $i++;
    }
=cut

=c
    sub step1 {
        my $n = shift;

        my %h = %hash;
        my $cur = delete $h{$n};
        my @word = split /\s+/, $cur->{text};

        my $match;
        for my $nn (keys %h) {
            my @tmp = split /\s+/, $h{$nn}{text};
            for my $w (@word) {
                $match->{$nn}++ if grep(/^$w$/, @tmp);
            }
            if ($match->{$nn}) {
                if ($match->{$nn} == 1) {
                    delete $match->{$nn};
                    next;
                }

                if ($match->{$nn} > $hash{$n}{cnt}) {
                    $hash{$n}{cnt}     = $match->{$nn};
                    $hash{$n}{matches} = { $nn => 1 };
                }
                elsif ($match->{$nn} == $hash{$n}{cnt}) {
                    $hash{$n}{matches}{$nn} = 1;
                }
            }
        }
        return unless %$match;

        # my $best;
        # for $n (sort { $match->{$b} <=> $match->{$a} } keys %$match) {
        #     $best ||= $match->{$n};
        #     delete $match->{$n} if $match->{$n} != $best;
        # }

        # return $match;
    }
=cut

    return template 'index' => {
        group => $res,
    };
};

true;
