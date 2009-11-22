#!/usr/bin/env python3

import bag
from dict import snarf_dictionary
from optparse import OptionParser
import os
from types import *
import sys

try:
    import psyco
    psyco.full()
    print( "Psyco loaded OK", file=sys.stderr)
except ImportError as e:
    print( "Psyco didn't load:", e, file=sys.stderr)

# try:
#     import profile
# except:
#     pass

def combine(words, anagrams):

    rv = []
    for w in words:
        for a in anagrams:
            rv.append([w] + a)

    return rv


def anagrams(b, dict):

    rv = []

    for words_processed in range(0, len(dict)):
        entry = dict[words_processed]
        key   = entry[0]
        words = entry[1]

        smaller_bag = b - key
        if not smaller_bag:
            continue

        if smaller_bag.empty():
            for w in words:
                rv.append([w])
            continue

        from_smaller_bag = anagrams(smaller_bag,
                                     dict[words_processed:])
        if not len(from_smaller_bag):
            continue

        rv.extend(combine(words, from_smaller_bag))

    return rv


if __name__ == "__main__":
    parser = OptionParser(usage="usage: %prog [options] string")
    parser.add_option("-d",
                      "--dictionary",
                      action="store",
                      type="string",
                      dest="dict_fn",
                      default=os.path.join(os.path.dirname(__file__), "../words.utf8"),
                      metavar="FILE",
                      help="location of word list")

    (options, args) = parser.parse_args()

    if not len(args):
        parser.print_help()
        sys.exit(0)

    dict_hash_table = snarf_dictionary(options.dict_fn)

    the_phrase = bag.Bag.fromstring(args[0])
    print( "Pruning dictionary.  Before:", len(dict_hash_table.keys()), "bags ...", file=sys.stderr)

    # Now convert the hash table to a list, longest entries first.  (This
    # isn't necessary, but it makes the more interesting anagrams appear
    # first.)

    # While we're at it, prune the list, too.  That _is_ necessary for the
    # program to finish before you grow old and die.


    the_dict_list = [[k, dict_hash_table[k]]
                     for k in dict_hash_table.keys()
                     if the_phrase - k]

    the_dict_list.sort(key=len)

    print("Pruned dictionary.  After:", len(the_dict_list), "bags.", file=sys.stderr)
    if "profile" in globals():
        profile.Profile.bias = 8e-06    # measured on dell optiplex, Ubuntu 8.04 ("Hoary Hedgehog")
        profile.run("result = anagrams(the_phrase, the_dict_list)", filename="profile-info")
    else:
        result = anagrams(the_phrase, the_dict_list)

    print(len(result), "anagrams of", sys.argv[1], ":", file=sys.stderr)

    for a in result:
        sys.stdout.write("(")
        for i, w in  enumerate(a):
            if i:
                sys.stdout.write(" ")
            sys.stdout.write(w)
        sys.stdout.write(")")
        sys.stdout.write("\n")
