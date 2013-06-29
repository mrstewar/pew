#!/bin/sh

#set -x

test_dir=$(cd $(dirname $0) && pwd)

export WORKON_HOME="$(echo ${TMPDIR:-/tmp}/WORKON_HOME | sed 's|//|/|g')"

#unset HOOK_VERBOSE_OPTION

setUp () {
    rm -rf "$WORKON_HOME"
    mkdir -p "$WORKON_HOME"
    rm -f "$test_dir/catch_output"
    echo
}

tearDown() {
    if type deactivate >/dev/null 2>&1
    then 
        deactivate
    fi
    rm -rf "$WORKON_HOME"
}

test_new_env_activated () {
	cd tests/testpackage
    echo "python setup.py install" | pew-new source >/dev/null 2>&1
    echo "" | pew-cp "source" "destination"
    pew-rm "source"
    testscript=$(echo "which testscript.py" | pew-workon destination | tail -n1)
	echo $testscript
    assertTrue "Environment test script not found in path" "[ $WORKON_HOME/destination/bin/testscript.py -ef $testscript ]"
    testscriptcontent="$(cat $testscript)"
    assertTrue "No pew-cptest in $testscriptcontent" "echo $testscriptcontent | grep pew-cptest"
}

test_virtual_env_variable () {
    echo "" | pew-new "source"
	echo "" | pew-cp "source" "destination"
    envname=$(echo "echo \$VIRTUAL_ENV" | pew-workon destination | tail -n1)
    assertSame "Wrong virtualenv name" "destination" $(basename $envname)
    assertTrue "$WORKON_HOME not in $envname" "echo $envname | grep -q $WORKON_HOME"
}

test_source_relocatable () {
    cd tests/testpackage
    echo "python setup.py install" | pew-new source >/dev/null 2>&1
    assertTrue "virtualenv --relocatable \"$WORKON_HOME/source\""
    echo "" | pew-cp "source" "destination"
    testscript=$(echo "which testscript.py" | pew-workon destination | tail -n1)
    assertTrue "Environment test script not the same as copy" "[ $WORKON_HOME/destination/bin/testscript.py -ef $testscript ]"
    envname=$(echo "echo \$VIRTUAL_ENV" | pew-workon destination | tail -n1)
    assertSame "Wrong virtualenv name" "destination" $(basename "$envname")
}

test_source_does_not_exist () {
    out="$(pew-cp virtualenvthatdoesntexist foo 2>&1)"
    assertSame "$out" "Please provide a valid virtualenv to copy"
}


test_no_site_packages () {
    # See issue #102
    echo "" | pew-new "source" --no-site-packages >/dev/null 2>&1
	echo "" | pew-cp "source" "destination"
    ngsp_file=$(echo "pew-sitepackages_dir" | pew-workon destination | tail -n1)"/../no-global-site-packages.txt"

    assertTrue "$ngsp_file does not exist in copied env" "[ -f \"$ngsp_file\" ]"
}

. "$test_dir/shunit2"

