#!/bin/bash
set -eu


versions=(
	6.0
	7.10
	8.10
        9.3
        9.10
)

declare -A aliases=(
	[6.0]='6 LTS-2014'
	[7.10]='7 LTS-2015'
	[8.10]='8 LTS-2016'
	[9.3]='FT'
	[9.10]='9 LTS-2017 LTS latest'
)

variants=(
	ubuntu
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"


# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

cat <<-EOH
# this file is generated via https://github.com/nuxeo/docker-nuxeo/blob/$(fileCommit "$self")/$self

Maintainers: Damien Metzler <dmetzler@nuxeo.com> (@damienmetzler),
             Arnaud Kervern <akervern@nuxeo.com> (@arnaudke)
GitRepo: https://github.com/nuxeo/docker-nuxeo.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}
for variant in "${variants[@]}"; do
	for version in "${versions[@]}"; do
		if [ $variant == "ubuntu" ]; then
			DIR=$version		
		else
			DIR=$version/$variant
		fi

		[ -f "$DIR/Dockerfile" ] || continue

		commit="$(dirCommit "$DIR")"
		versionAliases=(
			$version
			${aliases[$version]:-}
		)

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]/-ubuntu/}" )


		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			GitCommit: $commit
			Directory: $DIR
		EOE
	done
done
