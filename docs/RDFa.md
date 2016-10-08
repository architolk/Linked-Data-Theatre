# RDFa in a HTML page describing a vocabulary

Het LDT ondersteunt met de VocabularyAppearance de mogelijkheid om een een ontologie volledig te representeren als een HTML pagina. Deze HTML pagina bevat echter op zichzelf ook weer Linked Data, in de vorm van RDFa. Dit zorgt ervoor dat de HTML pagina zelf gelezen kan worden als RDF, hoewel via content-negotiation ook direct de RDF opgehaald kan worden.

Dit document geeft een specificatie van de wijze waarop de RDFa in het document wordt gebracht. Via de Html2Rdf transformator kan ook de omgekeerde route worden genomen: inlezen van een Html pagina waarin RDFa is verwerkt. Van dergelijke pagina's wordt verwacht dat ze zich aan de specificatie houden zoals in dit document geformuleerd

## Basics

The body of the html pagina should contain the following `prefix` attribute:

	<body prefix="owl: http://www.w3.org/2002/07/owl# rdfs: http://www.w3.org/2000/01/rdf-schema# rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns# sh: http://www.w3.org/ns/shacl#">

## Class
A class description should appear as:

	<div resource="/SomeClass" typeof="sh:Shape">
		<div resource="#SomeClass" typeof="owl:Class" property="sh:scopeClass">
			<h2 property="rdfs:label">Some class</h2>
			<a property="skos:broader" href="#BroaderClass">Some broader class</a>
			<div resource="/SomeClass/someAttribute" typeof="sh:propertyConstraint">
				<div resource="#someAttribute" typeof="owl:DatatypeProperty" sh:predicate>
					<span property="rdfs:label">some attribute</span> 
				</div>
			</div>
		</div>
	</div>
