--
-- NAME     dump_graphs.sql
-- VERSION  1.13.0
-- DATE     2016-12-06
--
-- Copyright 2012-2016
--
-- This file is part of the Linked Data Theatre.
--
-- The Linked Data Theatre is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- The Linked Data Theatre is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
--

-- -----
-- DESCRIPTION
-- Creates Virtuoso stored procedures to dump and load graphs (turtle and nquads variants)
--
-- This version creates uncompressed turtle files. Uncomment lines 98-99 to create compressed turtle files
--
-- -----
DROP PROCEDURE dump_one_graph;
CREATE PROCEDURE dump_one_graph 
  ( IN  srcgraph           VARCHAR
  , IN  out_file           VARCHAR
  , IN  file_length_limit  INTEGER  := 1000000000
  )
  {
    DECLARE  file_name     VARCHAR
  ; DECLARE  env
          ,  ses           ANY
  ; DECLARE  ses_len
          ,  max_ses_len
          ,  file_len
          ,  file_idx      INTEGER
  ; SET ISOLATION = 'uncommitted'
  ; max_ses_len  := 10000000
  ; file_len     := 0
  ; file_idx     := 1
  ; file_name    := sprintf ('%s%06d.ttl', out_file, file_idx)
  ; string_to_file ( file_name || '.graph', 
                     srcgraph, 
                     -2
                   );
    string_to_file ( file_name, 
                     sprintf ( '# Dump of graph <%s>, as of %s\n@base <> .\n', 
                               srcgraph, 
                               CAST (NOW() AS VARCHAR)
                             ), 
                     -2
                   )
  ; env := vector (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0)
  ; ses := string_output ()
  ; FOR (SELECT * FROM ( SPARQL DEFINE input:storage "" 
                         SELECT ?s ?p ?o { GRAPH `iri(?:srcgraph)` { ?s ?p ?o } } 
                       ) AS sub OPTION (LOOP)) DO
      {
        http_ttl_triple (env, "s", "p", "o", ses);
        ses_len := length (ses);
        IF (ses_len > max_ses_len)
          {
            file_len := file_len + ses_len;
            IF (file_len > file_length_limit)
              {
                http (' .\n', ses);
                string_to_file (file_name, ses, -1);
		gz_compress_file (file_name, file_name||'.gz');
		file_delete (file_name);
                file_len := 0;
                file_idx := file_idx + 1;
                file_name := sprintf ('%s%06d.ttl', out_file, file_idx);
                string_to_file ( file_name, 
                                 sprintf ( '# Dump of graph <%s>, as of %s (part %d)\n@base <> .\n', 
                                           srcgraph, 
                                           CAST (NOW() AS VARCHAR), 
                                           file_idx), 
                                 -2
                               );
                 env := VECTOR (dict_new (16000), 0, '', '', '', 0, 0, 0, 0, 0);
              }
            ELSE
              string_to_file (file_name, ses, -1);
            ses := string_output ();
          }
      }
    IF (LENGTH (ses))
      {
        http (' .\n', ses);
        string_to_file (file_name, ses, -1);
--	gz_compress_file (file_name, file_name||'.gz');
--	file_delete (file_name);
      }
  }
;
DROP PROCEDURE dump_graphs;
CREATE PROCEDURE dump_graphs 
  ( IN  dir               VARCHAR  :=  '../dumps'   , 
    IN  file_length_limit INTEGER  :=  1000000000
  )
  {
    DECLARE inx INT;
    inx := 1;
    SET ISOLATION = 'uncommitted';
    FOR ( SELECT * 
            FROM ( SPARQL DEFINE input:storage "" 
                   SELECT DISTINCT ?g { GRAPH ?g { ?s ?p ?o } . 
                                        FILTER ( ?g != virtrdf: ) 
                                      } 
                 ) AS sub OPTION ( LOOP )) DO
      {
        dump_one_graph ( "g", 
                         sprintf ('%s/graph%06d_', dir, inx), 
                         file_length_limit
                       );
        inx := inx + 1;
      }
  };
DROP PROCEDURE load_graphs;
CREATE PROCEDURE load_graphs 
  ( IN  dir  VARCHAR := '../dumps/' )
{
  DECLARE arr ANY;
  DECLARE g VARCHAR;

  arr := sys_dirlist (dir, 1);
  log_enable (2, 1);
  FOREACH (VARCHAR f IN arr) DO
    {
      IF (f LIKE '*.ttl')
	{
	  DECLARE CONTINUE HANDLER FOR SQLSTATE '*'
	    {
	      log_message (sprintf ('Error in %s', f));
	    };
  	  g := file_to_string (dir || '/' || f || '.graph');
	  DB.DBA.TTLP_MT (file_open (dir || '/' || f), g, g, 255);
	}
    }
  EXEC ('CHECKPOINT');
}
;
DROP PROCEDURE dump_nquads;
CREATE PROCEDURE dump_nquads 
  ( IN  dir                VARCHAR := '../dumps'
  , IN  start_from             INT := 1
  , IN  file_length_limit  INTEGER := 100000000
  , IN  comp                   INT := 1
  )
  {
    DECLARE  inx, ses_len  INT
  ; DECLARE  file_name     VARCHAR
  ; DECLARE  env, ses      ANY
  ;

  inx := start_from;
  SET isolation = 'uncommitted';
  env := vector (0,0,0);
  ses := string_output (10000000);
  FOR (SELECT * FROM (sparql define input:storage "" SELECT ?s ?p ?o ?g { GRAPH ?g { ?s ?p ?o } . FILTER ( ?g != virtrdf: ) } ) AS sub OPTION (loop)) DO
    {
      DECLARE EXIT HANDLER FOR SQLSTATE '22023' 
	{
	  GOTO next;
	};
      http_nquad (env, "s", "p", "o", "g", ses);
      ses_len := LENGTH (ses);
      IF (ses_len >= file_length_limit)
	{
	  file_name := sprintf ('%s/output%06d.nq', dir, inx);
	  string_to_file (file_name, ses, -2);
	  IF (comp)
	    {
	      gz_compress_file (file_name, file_name||'.gz');
	      file_delete (file_name);
	    }
	  inx := inx + 1;
	  env := vector (0,0,0);
	  ses := string_output (10000000);
	}
      next:;
    }
  IF (length (ses))
    {
      file_name := sprintf ('%s/output%06d.nq', dir, inx);
      string_to_file (file_name, ses, -2);
      IF (comp)
	{
	  gz_compress_file (file_name, file_name||'.gz');
	  file_delete (file_name);
	}
      inx := inx + 1;
      env := vector (0,0,0);
    }
}
;
