#!/bin/bash

set -e
set -o pipefail

if [ -z "${linting_path}" ] ; then
  echo " [!] Missing required input: linting_path"

  exit 1
fi

FLAGS=''

if [ -s "${lint_config_file}" ] ; then
  FLAGS=$FLAGS' --config '"${lint_config_file}"  
fi

if [ "${strict}" = "yes" ] ; then
  echo "Running strict mode"
  FLAGS=$FLAGS' --strict'
fi

if [ "${quiet}" = "yes" ] ; then
  echo "Running quiet mode"
  FLAGS=$FLAGS' --quiet'  
fi


cd "${linting_path}"

filename="swiftlint_report"
case $reporter in
    xcode|emoji)
      filename="${filename}.txt"
      ;;
    markdown)
      filename="${filename}.md"
      ;;
    csv|html)
      filename="${filename}.${reporter}"
      ;;
    checkstyle|junit)
      filename="${filename}.xml"
      ;;
    json|sonarqube)
      filename="${filename}.json"
      ;;
esac

report_path="${BITRISE_DEPLOY_DIR}/${filename}"

pwd

case $lint_range in 
  "changed")
  echo "Linting diff only"
    files=$(git diff HEAD^ --name-only -- '*.swift')

    echo $files

    for swift_file in $(git diff HEAD^ --name-only -- '*.swift')
    do 
      echo "command swiftlint lint --path \"$swift_file\" --reporter ${reporter} \"${FLAGS}\""
      swiftlint_output+=$"$(swiftlint lint --path $BITRISE_SOURCE_DIR/"$swift_file" --reporter ${reporter} "${FLAGS}")"
    done
    ;;
  
  "all") 
    echo "Linting all files"
    swiftlint_output="$(swiftlint lint --reporter ${reporter} ${FLAGS})"
    ;;
esac

# This will set the `swiftlint_output` in `SWIFTLINT_REPORT` env variable. 
# so it can be used to send in Slack etc. 
envman add --key "SWIFTLINT_REPORT" --value "${swiftlint_output}"
echo "Saved swiftlint output in SWIFTLINT_REPORT"

# This will print the `swiftlint_output` into a file and set the envvariable
# so it can be used in other tasks
echo "${swiftlint_output}" > $report_path
envman add --key "SWIFTLINT_REPORT_PATH" --value "${report_path}"
echo "Saved swiftlint output in file at path SWIFTLINT_REPORT_PATH"
 