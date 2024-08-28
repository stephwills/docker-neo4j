#!/usr/bin/env bash

ME=load-neo4j.sh

echo "($ME) $(date) Starting (from $IMPORT_DIRECTORY)..."
echo "($ME) $(date) Importing to database $IMPORT_TO"
echo "($ME) $(date) Database root is $NEO4J_dbms_directories_data"

# If the destination database exists
# then do nothing...
if [ ! -d $NEO4J_dbms_directories_data/databases/$IMPORT_TO.db ]
then
    echo "Running as $(id)"
    echo "($ME) $(date) Importing into '$NEO4J_dbms_directories_data/databases/$IMPORT_TO.db'..."

    cd $IMPORT_DIRECTORY
    /var/lib/neo4j/bin/neo4j-admin import \
        --database $IMPORT_TO.db \
        --skip-bad-relationships \
        --nodes "header-nodes.csv,nodes.csv.gz" \
        --relationships "header-edges.csv,edges_0.csv.gz" \
        --relationships "header-edges.csv,edges_1.csv.gz" \
        --relationships "header-edges.csv,edges_2.csv.gz" \
        --relationships "header-edges.csv,edges_3.csv.gz" \
        --relationships "header-edges.csv,edges_4.csv.gz" \
        --relationships "header-edges.csv,edges_5.csv.gz" \
        --relationships "header-edges.csv,edges_6.csv.gz" \
        --relationships "header-edges.csv,edges_7.csv.gz" \
        --relationships "header-edges.csv,edges_8.csv.gz" \
        --relationships "header-edges.csv,edges_9.csv.gz" \
        --relationships "header-edges.csv,edges_10.csv.gz" \
        --relationships "header-edges.csv,edges_11.csv.gz" \
        --relationships "header-edges.csv,edges_12.csv.gz" \
        --relationships "header-edges.csv,edges_13.csv.gz" \
        --relationships "header-edges.csv,edges_14.csv.gz" \
        --relationships "header-edges.csv,edges_15.csv.gz" \
        --relationships "header-edges.csv,edges_16.csv.gz" \

    echo "($ME) $(date) Imported."
else
    echo "($ME) $(date) Database '$IMPORT_TO' already exists."
fi

echo "($ME) $(date) Finished."
