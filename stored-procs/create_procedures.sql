--
-- NAME     create_procedures.sql
-- VERSION  1.8.0
-- DATE     2016-06-15
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
-- Creates the Virtuoso stored procedures used within the Linked Data Theatre
--
-- -----
drop procedure LDT.UPLOAD_RDF;
create procedure LDT.UPLOAD_RDF (in fname varchar, in graph varchar, in fdel varchar, in ftype varchar)
{
	log_enable(3,1);
	if (ftype = 'rdf' or ftype = 'ttl')
	{
		if (fdel = 'del')
		{
			exec(concat('sparql clear graph <',graph,'>'));
		}
		exec(concat('sparql insert into <',graph,'> {<',graph,'> rdf:type <http://rdfs.org/ns/void#Dataset>}'));
		if (ftype = 'rdf')
		{
			call DB.DBA.RDF_LOAD_RDFXML_MT(file_to_string_output(fname),'',graph);
		}
		if (ftype = 'ttl')
		{
			call DB.DBA.TTLP_MT(file_to_string_output(fname),'',graph);
		}
	}
};
drop procedure LDT.UPLOAD_NQ;
create procedure LDT.UPLOAD_NQ (in fname varchar)
{
	log_enable(3,1);
	call DB.DBA.TTLP_MT(file_to_string_output(fname),'','http://localhost:8890/default-graph',512);
};
-- Depricated: using MULTI_UPDATE_CONTAINER
drop procedure LDT.UPDATE_CONTAINER;
create procedure LDT.UPDATE_CONTAINER (in fname varchar, in ftype varchar, in pgraph varchar, in cgraph varchar, in targetgraph varchar, in action varchar, in postquery varchar)
{
	if (action = 'part') {
		exec(concat('sparql delete from <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
	}
	if (action = 'replace') {
		exec(concat('sparql clear graph <',targetgraph,'>'));
	}
	if (action<>'insert') {
		exec(concat('sparql clear graph<',cgraph,'>'));
	}
	if (ftype = 'ttl') {
		call DB.DBA.TTLP_MT(file_to_string_output(fname),'',cgraph);
	}
	if (ftype = 'xml') {
		call DB.DBA.RDF_LOAD_RDFXML_MT(file_to_string_output(fname),'',cgraph);
	}
	if (action = 'part' or action = 'replace') {
		exec(concat('sparql insert into <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
	}
	if (action='update') {
		exec(concat('sparql delete from <',targetgraph,'> {?s?x?y} where { graph <',targetgraph,'> {?s?x?y} graph <',cgraph,'> {?s?p?o}}'));
		--Some garbage collection of blank nodes is necessary, three times just to be sure (this deletes nested blank nodes to the third degree)
		exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
		exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
		exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
		exec(concat('sparql insert into <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
	}
	if (pgraph<>cgraph) {
		exec(concat('sparql insert into <',pgraph,'> {<',pgraph,'> <http://purl.org/dc/terms/hasVersion> <',cgraph,'>}'));
	}
	if (postquery<>'') {
		exec(concat('sparql ',postquery));
	}
};
drop procedure LDT.MULTI_UPDATE_CONTAINER;
create procedure LDT.MULTI_UPDATE_CONTAINER  (in flist varchar, in ftype varchar, in pgraph varchar, in cgraph varchar, in targetgraph varchar, in action varchar, in postquery varchar)
{
	declare message varchar;
	message := 'succes';
	declare exit handler for sqlexception message := __SQL_MESSAGE;
	{
		if (action = 'part') {
			exec(concat('sparql delete from <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
		}
		if (action = 'replace') {
			exec(concat('sparql clear graph <',targetgraph,'>'));
		}
		if (action is null or action<>'insert') {
			exec(concat('sparql clear graph<',cgraph,'>'));
		}
		
		declare fvector any;
		fvector := split_and_decode(flist,0,'\0\0,');
		foreach (varchar fname in fvector) do {
			if (ftype = 'ttl') {
				call DB.DBA.TTLP_MT(file_to_string_output(fname),'',cgraph);
			}
			if (ftype = 'xml') {
				call DB.DBA.RDF_LOAD_RDFXML_MT(file_to_string_output(fname),'',cgraph);
			}
		}
		
		if (action = 'part' or action = 'replace') {
			exec(concat('sparql insert into <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
		}
		if (action='update') {
			exec(concat('sparql delete from <',targetgraph,'> {?s?x?y} where { graph <',targetgraph,'> {?s?x?y} graph <',cgraph,'> {?s?p?o}}'));
			--Some garbage collection of blank nodes is necessary, three times just to be sure (this deletes nested blank nodes to the third degree)
			exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
			exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
			exec(concat('sparql delete from <',targetgraph,'> {?bs?bp?bo} where { graph <',targetgraph,'> {?bs?bp?bo FILTER(isblank(?bs)) FILTER NOT EXISTS {?s?p?bs}}}'));
			exec(concat('sparql insert into <',targetgraph,'> {?s?p?o} where { graph <',cgraph,'> {?s?p?o}}'));
		}
		if (pgraph<>cgraph) {
			exec(concat('sparql insert into <',pgraph,'> {<',pgraph,'> <http://purl.org/dc/terms/hasVersion> <',cgraph,'>}'));
		}
		if (postquery<>'') {
			exec(concat('sparql ',postquery));
		}
	}
	result_names (message);
	result (message);
};

drop procedure UCamelCase;
create procedure UCamelCase (in istr varchar)
{
	declare svector any;
	declare res varchar;
	res := '';
	svector := split_and_decode(regexp_replace(istr,'\\.|,|:|;|\\?|!|\\+',' '),0,'\0\0 ');
	foreach (varchar prt in svector) do {
		if (length(prt)=1) {
			res := concat(res,ucase(prt));
		} else {
			if (length(prt)>1) {
				res := concat(res,ucase(substring(prt,1,1)),substring(prt,2,255));
			}
		}
	}
	res := regexp_replace(res,'[^a-zA-Z0-9_()~-]','');
	if (regexp_like(res,'^[0-9]')) {
		res := concat('_',res);
	}
	return (res);
};
grant execute on UCamelCase to public;

drop procedure LCamelCase;
create procedure LCamelCase (in istr varchar)
{
	declare svector any;
	declare res varchar;
	declare frst int;
	res := '';
	svector := split_and_decode(regexp_replace(istr,'\\.|,|:|;|\\?|!|\\+',' '),0,'\0\0 ');
	frst := 1;
	foreach (varchar prt in svector) do {
		if (frst=1) {
			if (length(prt)=1) {
				res := concat(res,lcase(prt));
			} else {
				if (length(prt)>1) {
					res := concat(res,lcase(substring(prt,1,1)),substring(prt,2,255));
				}
			}
			frst:=0;
		} else {
			if (length(prt)=1) {
				res := concat(res,ucase(prt));
			} else {
				if (length(prt)>1) {
					res := concat(res,ucase(substring(prt,1,1)),substring(prt,2,255));
				}
			}
		}
	}
	res := regexp_replace(res,'[^a-zA-Z0-9_()~-]','');
	if (regexp_like(res,'^[0-9]')) {
		res := concat('_',res);
	}
	return (res);
};
grant execute on LCamelCase to public;

drop procedure StrDateDiff;
create procedure StrDateDiff (in dstr varchar)
{
	return datediff('day',now(),stringdate(left(dstr,10)));
};
grant execute on StrDateDiff to public;

drop procedure GetMD5Hash;
create procedure GetMD5Hash (in fragment varchar)
{
	return md5(fragment);
};
grant execute on GetMD5Hash to public;
