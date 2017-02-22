# semver - bump version component
# Usage:
#   semver_bump <Version> <Component> <Increment>
# Component can be one of "major", "minor" or "patch"
semver_bump() {
    local current_version="${1:-}"
    local which="${2:-patch}"
    local increment="${3:-1}"
    local major minor patch
    { [[ "$increment" =~ ^[0-9]+$ ]] && [[ "$current_version" =~ ^([0-9]+)(\.([0-9]+))?(\.([0-9]+))?$ ]]; } && {
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[3]:-0}"
        patch="${BASH_REMATCH[5]:-0}"

        case "$which" in
            major)
                major=$((major+increment))
                minor=0
                patch=0
                ;;
            minor)
                minor=$((minor+increment))
                patch=0
                ;;
            patch)
                patch=$((patch+increment))
                ;;
            *)
                return 1;
        esac
        printf "%d.%d.%d" "$major" "$minor" "$patch"
    }
}

# Normalise a given semver
#
# Usage: semver_normalise <SemVer>
#
# Example: 1.0 becomes 1.0.0
semver_normalise() {
    semver_bump "$1" patch 0
}
