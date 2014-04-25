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
				//empty text tags appear n 
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