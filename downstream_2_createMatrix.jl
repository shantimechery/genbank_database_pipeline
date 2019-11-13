#=
This program takes in the names of a phrase and file names mapped host x speices, and output, and creates a matrix of hosts x species associated with phrase
**Double check the column names of CSV match column attributes in code**

=#
using DelimitedFiles, CSV, Suppressor


function hostSpeciesMappings_set(phrase, hostFile)

	hostNames=Set(String[])
	speciesNames=Set(String[])
	speciesHost=Dict{String,Array{String}}()
	open(hostFile) do hostFile
		@suppress begin
			for row in CSV.File(hostFile)
				if occursin(phrase, row.preferred)
					if (!(row.species in speciesNames) | !(row.host_cleaned in hostNames)) & (row.host_cleaned!="NULL")
						push!(speciesNames, row.species)
						push!(hostNames, row.host_cleaned)
						if haskey(speciesHost, row.species)
							push!(speciesHost[row.species], row.host_cleaned)
						else
							speciesHost[row.species]=[row.host_cleaned]
						end
					end
				end
			end
		end
	end
	return hostNames, speciesNames, speciesHost
end

function hostSpecieMatrix(hostNames, speciesNames, speciesHost, outputFile)
	hostNames=collect(hostNames)
	speciesNames=collect(speciesNames)
	speciesIndices=Dict{String,Array{Int64}}()
	for mapping in speciesHost
		specie=String(mapping[1])
		specieIndex=findall(x->x==specie,speciesNames)
		for host in mapping[2]
			if haskey(speciesIndices,host)
				speciesIndices[host]=vcat(speciesIndices[host],specieIndex)
			else
				speciesIndices[host]=specieIndex
			end	
		end
		
	end
	
	open(outputFile,"a") do outputFile
		write(outputFile,string("#nexus\nbegin data;\n"))
		write(outputFile, string("dimensions ntax=", length(hostNames), " nchar=", length(speciesNames), ";\n"))
		species=string(speciesNames)
		species=replace(species,", "=>",")
		species=replace(species," "=>"_")
		species=replace(species,","=>" ")
		species=replaceAll(species, ["(", ")","[", "]","{", "}",'"',''', ";","/", ":", "=", "*", "+", "-", "<", ">","@"])
		write(outputFile, string("charlabels ", species, ";\n"))
		write(outputFile, "matrix\n")
		for mapping in speciesIndices
			row = zeros(Int8,length(speciesNames))
			for i in mapping[2]
				row[i]=1
			end
			row=string(row)
			row =replace(row, "Int8["=>"")
			row =replace(row, ","=>"")
			row =replace(row, "]"=>"")
			host=replace(mapping[1]," "=>"_")
			host=replaceAll(host,["(", ")","[", "]","{", "}",'"',''',",", ";", ":", "=", "*", "+", "-", "<", ">","@"])
			write(outputFile, string(host," ",row,'\n'))
		end
		write(outputFile, ";\n")
		write(outputFile, "end;\n")

	end
end

function replaceAll(str, replacements)
	for r in replacements
		str=replace(str, r=>"")
	end
	return str
end

function main(args)
	if length(args)==3
		hostNames, speciesNames, speciesHost=hostSpeciesMappings_set(uppercase(args[1]),args[2])
		hostSpecieMatrix(hostNames, speciesNames, speciesHost, args[3])
		
	else
		println("please enter the names of phrase, and mapped speices to host, and output files as commandline arguments.")
	end

end

main(ARGS)