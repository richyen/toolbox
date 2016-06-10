#!/usr/bin/python
import random
import smtplib 

#randomly divide a list of items into two groups

def main():
    data = []
    num_per_group = len(data) / 2  #always gives an int (rounds down)
    groups_text = dist_groups(data, num_per_group)
    print groups_text)

def dist_groups(data, num_per_group):
    group_assignment = ''
    while len(data) > num_per_group:
        rand = random.Random()
        rand.jumpahead(1)
        rand_index = rand.randint(0, len(data) - 1) 
        item = data[rand_index]
        data.remove(item)
        group_assignment += item + "\n"

    group_assignment += "\nGroup #2:\n"
    remainder_data = "\n".join(data)
    group_assignment += remainder_data

    return group_assignment
