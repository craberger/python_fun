import emptyheaded 

class ResultError(Exception):
    pass

def main():
  db_config="$EMPTYHEADED_HOME/examples/rdf/data/lubm1/config.json"
  emptyheaded.createDB(db_config)

if __name__ == "__main__": main()
