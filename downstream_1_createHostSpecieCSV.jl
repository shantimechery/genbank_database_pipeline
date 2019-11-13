#=
This file creates a csv of locus, original, preferredspecies, host from the 
cleaned_annotations genbank csv and speciesMetaMap files
(note only need locus,originalName,cleanScientificName from clean_annotations)
**Double check the column names of CSV match column attributes in code**
=#



using DelimitedFiles, CSV, Suppressor

function parseCleaned_Host_Annotations(hostFile)
	hostsDict=Dict{String,String}() 
	open(hostFile) do hostFile
		@suppress begin
			for row in CSV.File(hostFile)
				if row.cleanScientificName!="NULL"
					hostsDict[row.locus]=row.cleanScientificName
				end
			end
		end
	end

	return hostsDict
end

function mapSpeciesHosts(hostsDict, speciesFile, outputFile)
	open(speciesFile) do speciesFile
		open(outputFile, "a") do outputFile
			@suppress begin
				for row in CSV.File(speciesFile)
					if haskey(hostsDict, row.locus)
						writedlm(outputFile, [row.locus uppercase(row.original) uppercase(row.preferred) row.species hostsDict[row.locus]], ',')
					else
						writedlm(outputFile, [row.locus uppercase(row.original) uppercase(row.preferred) row.species "NULL" "NULL"], ',')
					end
				end
			end
		end
	end

end




function main(args)
	if length(args)==3
		if !(isfile(args[3]))
			open(args[3], "a") do outputFile
				writedlm(outputFile, ["locus" "original" "preferred" "species" "host_cleaned"], ',')
			end
		end
		hosts=parseCleaned_Host_Annotations(args[1])
		mapSpeciesHosts(hosts, args[2], args[3])
	else
		println("please enter the names of cleaned_annotations file, species file, and output files as commandline arguments.")
	end
end

main(ARGS)