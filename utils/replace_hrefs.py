#!/usr/bin/python
import string
import re
import sys
import os
import htmllib, formatter

def chomp(string):
    string = string[:-1]
    return string

def main():
    basedir = ''
    newdir = ''
    fname = sys.argv[1]
    print "DEBUG: Going to look in file '%s'" % (fname)
    file_text = read_file(basedir+fname)
    if file_text == None:
        return "%s is directory" % fname
    print 'DEBUG: after read_file is %s' % file_text

    count = len(find_hrefs(file_text))
    if count == 0:
        print "no matches found in file %s" % (fname)
        return
    print "there are %s matches in file %s" % (count, fname)

    file_text = fix_ampersands(file_text)
    print 'DEBUG: after fix_ampersands is %s' % file_text

    file_text = fix_equals(file_text)
    print 'DEBUG: after fix_equals is %s' % file_text

    newfile = open(newdir+fname, 'w')
    newfile.write(file_text)
    newfile.close()

def read_file(fname):
    if os.path.isdir(fname):
        return None
    try:
        f = open(fname)
    except IOError, e:
        print '%s is not able to be opened: %s' % (fname, e)
    file_text = f.read()
    f.close()
    return file_text

def find_hrefs(file_text):
    regexp = re.compile('\<a.*?href=[\"|\'](.*?)[\"|\'].*?\>', re.X | re.M | re.S | re.I)
    match_list = regexp.findall(file_text)
    return match_list

def fix_ampersands(file_text):
    text_fixed = file_text
    regexp = re.compile('\<a.*?href=[\"|\'](.*?)[\"|\'].*?\>', re.X | re.M | re.S | re.I)
    for m in regexp.finditer(file_text):
        href_text  = m.string[m.start(1):m.end(1)]
        href_re    = re.compile('(?<!&)&(?!&)', re.X | re.M | re.S | re.I)
        m2         = href_re.search(href_text)
        if m2:
            href_fixed = href_re.sub('&amp;', href_text)
            print "DEBUG: fixed from %s to %s" % (href_text, href_fixed)
        else:
            continue

        clean_href = re.compile('(?P<blah>[\(\)\<\>\{\}\$\+\-\. \?])', re.X | re.M | re.S | re.I)
        cleaned_href = clean_href.sub("\\\\\g<blah>", href_text)

        convert_nl = re.compile('\n', re.M | re.S | re.I)
        no_nl = convert_nl.sub('\\\\n', cleaned_href)

        convert_tab = re.compile('\t', re.M | re.S | re.I)
        no_tab = convert_tab.sub('\\\\t', no_nl)

        text_regexp = re.compile(no_tab, re.X | re.M | re.S | re.I)
        print "DEBUG: pattern is %s" % text_regexp.pattern
        m = text_regexp.search(file_text)
        if (m != None):
            print "YAHOO: match found"
        text_fixed = text_regexp.sub(href_fixed, text_fixed, 1)
    return text_fixed

def fix_equals(file_text):
    text_fixed = file_text
    regexp = re.compile('\<a.*?href=[\"|\'](.*?)[\"|\'].*?\>', re.X | re.M | re.S | re.I)
    for m in regexp.finditer(file_text):
        href_text  = m.string[m.start(1):m.end(1)]
        href_re    = re.compile('(?<!=|%|!|\+|\ )=(?!~|=|window)', re.X | re.M | re.S | re.I)
        m2         = href_re.search(href_text)
        if m2:
            href_fixed = href_re.sub('&#61;', href_text)
            print "DEBUG: fixed from %s to %s" % (href_text, href_fixed)
        else:
            continue

        clean_href = re.compile('(?P<blah>[\(\)\<\>\{\}\$\+\-\. \?])', re.X | re.M | re.S | re.I)
        cleaned_href = clean_href.sub("\\\\\g<blah>", href_text)

        convert_nl = re.compile('\n', re.M | re.S | re.I)
        no_nl = convert_nl.sub('\\\\n', cleaned_href)

        convert_tab = re.compile('\t', re.M | re.S | re.I)
        no_tab = convert_tab.sub('\\\\t', no_nl)

        text_regexp = re.compile(no_tab, re.X | re.M | re.S | re.I)
        print "DEBUG: pattern is %s" % text_regexp.pattern
        m = text_regexp.search(file_text)
        if (m != None):
            print "WOOHOO: match found"
        text_fixed = text_regexp.sub(href_fixed, text_fixed, 1)
    return text_fixed

main()
