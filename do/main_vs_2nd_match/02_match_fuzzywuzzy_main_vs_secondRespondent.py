# -*- coding: utf-8 -*-
"""
@author: mkj
"""
import pandas as pd
from pandas import DataFrame
from fuzzywuzzy import process
from fuzzywuzzy import fuzz
import csv

save_file = open('C:\Users\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\July17\checks\intermediate\match_main_vs_second_respondent.csv', 'w')
writer = csv.writer(save_file, lineterminator = '\n')

def parse_csv(path):

    with open(path,'r') as f:
        reader = csv.reader(f, delimiter=',')
        for row in reader:
            
            yield row

if __name__ == "__main__":
    for row1 in parse_csv('C:\Users\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\July17\checks\intermediate\Second_respondent.csv'):
    # For each row in the lookup compute the partial ratio
        max_score = 0
        max_match_r0 = ""
        max_match_r1 = ""
        max_match_r2 = ""
        max_match_r3 = ""
        max_match_r4 = ""
        max_match_r5 = ""
        max_match_r6 = ""
        max_match_r7 = ""
        max_match_r8 = ""
        max_match_r9 = ""
        for row2 in parse_csv('C:\Users\MKEDIRJEMAL\Dropbox (IFPRI)\Catherine\Aquaculture\July17\checks\intermediate\Main_respondent.csv'):
            if fuzz.token_set_ratio(row1[2],row2[7]) == 100: 
                score=fuzz.token_set_ratio(row1[1],row2[1])
                if score > max_score:
                    max_score = score
                    max_match_r9 = row2[9]
                    max_match_r8 = row2[8]
                    max_match_r7 = row2[7]
                    max_match_r6 = row2[6]
                    max_match_r5 = row2[5]
                    max_match_r4 = row2[4]
                    max_match_r3 = row2[3]
                    max_match_r2 = row2[2]
                    max_match_r1 = row2[1]
                    max_match_r0 = row2[0]
        print("%i: %s | %s" % (max_score, row1[1], max_match_r1))
        Digi_Results = [row1[0],row1[1],row1[2],row1[3],row1[4],row1[5],row1[6],row1[7], max_score, max_match_r0,max_match_r1,max_match_r2,max_match_r3,max_match_r4,max_match_r5,max_match_r6,max_match_r7,max_match_r8] ##,max_match_r9]
        writer.writerow(Digi_Results)
    save_file.close()
 
