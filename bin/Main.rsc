module Main

import IO;
import lang::html::IO;
import String;
import Type;
import List;
import Relation;
import ListRelation;

anno str node@id;
anno str node@href;
anno str node@class;


loc baseLoc = |https://github.com|;

// @TODO Next button
// @TODO Major / minor releases
// @TODO handle repo links from csv input
// @TODO handle collapsed

public void testMethod(str testlink){
	str repo = normalizeLink(testlink);
	int noReleases = numberOfReleases(repo);
	println(noReleases);
	if(noReleases > 0){
		lrel[str,str] releases = releases(repo);
		println(releases);
	}
	else{
		println("No releases available on Github");
	}	
}


/*
	Input format:	
	https://api.github.com/repos/cargomedia/jquery.touchToClick 
	output: /cargomedia/jquery.touchToClick	
*/
public str normalizeLink(str githubLink){

	if(/.*repos<rest:.*>/ := githubLink){
		return rest;
	}
	else{
		return "";
	}
}

//minor releases
//8 months ago  - jedis-2.2.1 …
public lrel[str,str] releases(str repo){

	loc url = baseLoc + repo + "/releases";
	
	node html = readHTMLFile(url);
	lrel[str,str] information = [];
	
	visit(html){
		case li:"li"(linky):{
			str date = "";
			str rel_tag= "";
			
			visit(linky){
				case time:"span"(time_span): if((time@class ? "") == "date"){
					date = getDate(time);
				}
				case div:"div"(infos): if((div@class ? "") == "main"){
					rel_tag = getReleaseTag(div);	
					relation = <date,rel_tag>;
					information += relation;
				}	
			}
		}
	}
	return information;
}

//major releases
//jedis-2.2.0 - v2.2.0 Jonathan Leibiusky xetorthio released this 8 months ago ·

public lrel[str,str] majorReleases(str repo){

	loc url = baseLoc + repo + "/releases";
	lrel[str,str] releases = [];
	println(url);
	node html = readHTMLFile(url);
	visit(html){
		case release:"div"(release_info):
		 if((release@class ? "") == "release label-latest" || (release@class ? "") == "release label-"){
			releases += majorRelease(release);
		}
		
	}
	return releases;
}

public lrel[str,str] majorRelease(node release){
 str release_info = "";
 str date_info = "";
	visit(release){
		case header:"h1"(header_info): if((header@class ? "") == "release-title"){ 
			visit(header){
				case headerText:"text"(release_header): {
					release_info = release_header;
				}
			}
		}
		case authorship:"p"(author_info): if((authorship@class ? "") == "release-authorship"){
			int i = 0;
			visit(authorship){
				case text:"text"(date):{
					i = i + 1;
					if(i == 3){
						date_info = date;
					}
				}
			}
		}
	}	
	lrel[str,str] list_rel = [] + <release_info, date_info>;
	return list_rel;
}	
			
public str getDate(node nod){
	visit(nod){
		case text:"text"(date_release):{
			date = date_release;
			if(date != " "){
	  			return date;
			}
		}
	}
}

public str getReleaseTag(node nod){
	visit(nod){
		case l:"a"(l2): if(/.*releases.*/ := (l@href ? "")){
			visit(l2){
				case release_tag:"text"(release):{											
				rel_tag = release;
				//empty text tags appear in html source
					if(rel_tag != " "){
	  					return rel_tag;
	  				}
				}
			}
		}
	}
}

public int numberOfReleases(str repo){
	
	loc url = baseLoc + repo;
	node html = readHTMLFile(url);
	visit(html){
		case link:"a"(link_release): if((link@href ? "") == (repo + "/releases")){
	 		visit(link){
	 			case span:"span"(span_input): if((span@class ? "") == "num"){
					visit(span){
						case txt:"text"(bla):{
							return toInt(replaceAll(bla," ",""));
						}
					}
				}
			}
		}
	}
	return 0;
}