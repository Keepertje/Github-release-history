module Main

import IO;
import lang::html::IO;
import lang::csv::IO;
import String;
import Type;
import List;
import Exception;
import Relation;
import Set;
import util::Math;
import ListRelation;

anno str node@id;
anno str node@href;
anno str node@class;


str baseLoc = "https://github.com";

// @TODO handle repo links from csv input
public void main(loc csvLocation = |file:///Users/Cindy/Documents/Github/Github-release-history/input.csv|){
	lrel[str,str] input = toList(readCSV(#rel[str api, str projectName],csvLocation));
	for(int n <- [0..(size(input)-1)] ){
		testMethod(input[n]);
	}
	//output = mapper(input.api, testMethod);
	//println(output);


}

public lrel[str,str] testMethod(tuple[str,str] input_project){// = "http://www.api.github.com/repos/xetorthio/jedis"){
	tuple[str api, str name] project = input_project;
	str testlink = project.api;
	str link = normalizeLink(testlink);
	int noReleases = numberOfReleases(link);
	println(testlink + " "  +toString(noReleases));
	if(noReleases > 0){
		str repo = baseLoc + link;
		lrel[str,str] releases = releases(repo, "/releases") + 
			majorReleases(repo, "/releases") + nextButton(repo, "/releases");
			
		//println(link);
		//println(releases);
		//println(size(releases) == noReleases);
		rel[str date, str version] allReleases = toSet(releases);
		loc write = |file:///Users/Cindy/Documents/Github/Github-release-history/|;
		
		str csv_name = project.name + ".csv";
		write = write + "csvfiles/" + csv_name;
		writeCSV(allReleases, write);
		return(releases);
	}
	else{
		println("No releases available on Github for " + link);
		return([]);
	}	
}

public lrel[str,str] nextButton(str repo, str added){
	loc url = toLocation(repo + added);
	node html = readHTMLFile(url);
	lrel[str,str] information = [];
	visit(html){
		case page:"div"(pages): if((page@class ? "") == "pagination"){
			visit(page){
				case span:"span"(dis_button): if((span@class ? "") == "disabled"){
					visit(span){
						case text:"text"(button):{
							if(button == "Next »"){
							 	println("End of releases");
							 	return [];
							}						
						}
					}
				}
				case link:"a"(next_page):{
					visit(link){
						case txt:"text"(button):{
							if(button == "Next »"){
								str nextpage = "/releases" + normalizeLink(link@href);
								information += releases(repo, nextpage) + majorReleases(repo,nextpage);
								information += nextButton(repo, nextpage);
							}
						}
					}
				} 
			}
		}
	}
	return information;
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
	else if(/.*releases<rest:.*>/ := githubLink){
		return rest;
	}
	else{
		return "";
	}
}


//minor releases
//8 months ago  - jedis-2.2.1 …
public lrel[str,str] releases(str repo, str add){
	
	loc url = toLocation(repo + add);

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
					relation = <rel_tag,date>;
					information += relation;
				}	
			}
		}
	}
	
	println(toString(size(information)) + " minor releases");
	return information;
}

//major releases
//jedis-2.2.0 - v2.2.0 Jonathan Leibiusky xetorthio released this 8 months ago ·

public lrel[str,str] majorReleases(str repo, str add){

	loc url = toLocation(repo + add);
	lrel[str,str] releases = [];
	node html = readHTMLFile(url);
	visit(html){
		case release:"div"(release_info):
		 if((release@class ? "") == "release label-latest" || (release@class ? "") == "release label-"
		 	|| (release@class ? "") == "release label-prerelease"){
			releases += majorRelease(release);
		}
		
	}
	println(toString(size(releases)) + " major releases");
	return releases;
}

public lrel[str,str] majorRelease(node release){
 str release_info = "";
 str date_info = "";
	visit(release){
		case header:"h1"(header_info): if((header@class ? "") == "release-title"){ 
			visit(header){
				case headerText:"text"(release_header): {
					//println(release_header);
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
	loc url = toLocation(baseLoc + repo);
	println(url);
	
	try node html = readHTMLFile(url);
	catch: return 0;
	
	visit(html){
		case link:"a"(link_release): if((link@href ? "") == (repo + "/releases")){
	 		visit(link){
	 			case span:"span"(span_input): if((span@class ? "") == "num"){
					visit(span){
						case txt:"text"(inhoudt):{
							str number = replaceAll(replaceAll(inhoudt,",","")," ","");
							return toInt(number);
						}
					}
				}
			}
		}
	}
	return 0;
}
