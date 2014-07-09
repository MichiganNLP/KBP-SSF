Files:
  *anchor.csv
  *categorylink.csv
  *page.csv
were obtained from Samer (from his pre-processing of Wikipedia)
saved on 1.5 TB /shassan/Data/Wikipedia/20110316/en/

Note: the files are generally created in the shared folder, under entity_disambiguation

Create the following soft links (in case git did not add them):
data -> /local/KBP-SSF-2014/KB/TAC_2009_KBP_Evaluation_Reference_Knowledge_Base/data
kb_to_wiki_id -> /local/KBP-SSF-2014/entity_disambiguation/kb_to_wiki_id
page.csv -> /local/KBP-SSF-2014/entity_disambiguation/page.csv
anchor_probability.csv -> /local/KBP-SSF-2014/entity_disambiguation/anchor_probability.csv
tmp -> /local/KBP-SSF-2014/entity_disambiguation/tmp
corpus -> /local/KBP-SSF-2014/TAC_KBP_2013_Source_Corpus_Sample_SERIF_Annotation/data
annotated -> /local/KBP-SSF2014/entity_disambiguation/annotated 

1. perl calculate_anchor_probability.pl
  - generates anchor_probability.csv
  - generates files in data/
2. ./resolve_kb_wikipedia_id.sh
  - processes the files in data/ and stores their processed version in kb_to_wiki_id/
3. perl resolve_kb_anchor.pl kb_to_wiki_id/ kb_to_anchor/
  - generates files in kb_to_anchor/
4. perl load_finalized_kb.pl
  - generates lookup hashes (anchor to KBid & KBid to anchor)
  - achor_to_KB.object (and its readable dump anchor_to_KB.object.txt)
  - kb_to_anchor.object (and its readable dump kb_to_anchor.object.txt) 
5.a) perl resolve_annotations_kb_ids.pl /home/carmen/Research/KBP/KBP-Corpus/SERIF_Annotations/newswire/AFP_ENG_200905/ tmp/ anchor_to_KB.object
or 
5.b) perl new_resolve_annotations_kb.pl corpus/ annotated/ anchor_to_KB.object
