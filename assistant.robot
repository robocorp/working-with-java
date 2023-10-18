*** Settings ***
Library     RPA.JavaAccessBridge
...         ignore_callbacks=True    WITH NAME    Java
Library     Process
Library     Collections
Library     RPA.FileSystem
Library     CustomAssistant.py    # RPA.Assistant
Library     RPA.Windows
Library     String


*** Variables ***
${ELEMENT_TREE_LOADED}                  ${FALSE}
${RESULT_ELEMENT_TYPE}                  ${NONE}
${SELECTED_FILE}                        ${NONE}
@{FOUND_ELEMENTS}                       @{EMPTY}
&{FOUND_ROLES}                          &{EMPTY}
${JAVA_WINDOW_SELECTED}                 ${FALSE}
${SELECTED_WINDOW_NAME}                 ${NONE}
${INSPECT_ONLY_VISIBLE}                 ${TRUE}
${INSPECT_LOCATOR}                      ${NONE}
${LOCATOR_TREE_FILE}                    %{ROBOT_ARTIFACTS}${/}locator-tree.txt
${ELEMENT_TREE_FILE}                    %{ROBOT_ARTIFACTS}${/}element-tree.txt
${JAVA_WINDOW_DROPDOWN_SELECTION}       ${NONE}
${FIND_STRING}                          ${EMPTY}
${FOUND_LOCATORS_RAW}                   ${EMPTY}


*** Tasks ***
Assistant Main
    [Documentation]
    ...    The Main task running the Assistant
    ...    Configure your window behaviour here

    Display Main Menu
    ${result}=    Run Dialog
    ...    title=Assistant for Java
    ...    on_top=False
    ...    height=800
    ...    width=800
    ...    timeout=3600


*** Keywords ***
Display Main Menu
    [Documentation]
    ...    Main UI of the bot. We use the "Back To Main Menu" keyword
    ...    with buttons to make other views return here.

    Clear Dialog
    Add Heading    Java UI Element Tree Assistant
    ${javas}=    List Java Windows
    Log List    ${javas}    level=WARN

    IF    len($javas)==0
        Add Text    No Java applications open.
        Open Row
        Add Next UI Button    Refresh Java window list    Refresh UI
        Add Submit Buttons    buttons=Close    default=Close
        Close Row
        RETURN
    END

    @{titles}=    Evaluate    [obj.title for obj in $javas]
    IF    not ${JAVA_WINDOW_SELECTED}
        ${default}=    Evaluate    max(@{titles}, key = len)
    ELSE
        ${default}=    Set Variable    ${SELECTED_WINDOW_NAME}
    END
    Add Drop-Down
    ...    name=selected_java_window
    ...    options=@{titles}
    ...    default=${default}
    ...    label=Select Java window and load element tree
    Open Row
    Add Next UI Button    Refresh Java window list    Refresh UI
    Add Next UI Button    Load/Refresh element tree    Load Element Tree
    Close Row

    IF    ${ELEMENT_TREE_LOADED} == ${False}
        Add Submit Buttons    buttons=Close    default=Close
        RETURN
    END

    Add Heading    Actions:    Small

    Add Text    Inspect a locators:
    Add Text Input    locator    default=${INSPECT_LOCATOR}    placeholder=Input Locator e.g.: role:menu and name:FILE
    Open Row
    Add Next UI Button    Inspect Locator    Inspect Tree
    Add Checkbox    only_visible    Target only visible elements    ${INSPECT_ONLY_VISIBLE}
    Close Row

    Add Text    List roles and the full tree:
    Open Row
    Add Next UI Button    List element roles    List Element Roles
    Add Next UI Button    View locator tree    List Locator Tree
    Add Next UI Button With Tooltip
    ...    Write locator tree to file
    ...    Write locator tree to file
    ...    Files to be saved:\nLocator tree file: ${LOCATOR_TREE_FILE}\nElement tree file: ${ELEMENT_TREE_FILE}
    Close Row

    IF    ${RESULT_ELEMENT_TYPE} == "ROLES"
        Show Roles Results
    ELSE IF    ${RESULT_ELEMENT_TYPE} == "ELEMENTS"
        Show Element Results
    ELSE IF    ${RESULT_ELEMENT_TYPE} == "LOCATORS"
        Show Locator Results
    ELSE IF    ${RESULT_ELEMENT_TYPE} == "FIND"
        Show Locator Results    ${FIND_STRING}
    ELSE
        Add Submit Buttons    buttons=Close    default=Close
        RETURN
    END
    Add Submit Buttons    buttons=Close    default=Close

Refresh UI
    [Arguments]    ${result}
    Clear Dialog
    Display Main Menu
    Refresh Dialog

Find Selected Window
    [Arguments]    ${java_windows}    ${selected_title}
    FOR    ${java_window}    IN    @{java_windows}
        Log    ${java_window}
        IF    "${java_window.title}" == "${selected_title}"
            RETURN    ${java_window}
        END
    END

Select Java Window
    [Arguments]    ${result}
    ${javas}=    List Java Windows
    IF    not $result.selected_java_window
        Open Row
        Add icon    Warning    size=24
        Add text    There are no detected Java windows
        Close Row
    ELSE
        ${selected_java_window}=    Find Selected Window    ${javas}    ${result.selected_java_window}
        IF    not $selected_java_window
            Open Row
            Add icon    Warning    size=24
            Add text    The window ${result.selected_java_window} is not visible
            Close Row
        ELSE
            Add text    Target: ${{ $selected_java_window.title }}
            IF    not ${JAVA_WINDOW_SELECTED}
                Select Window By Title    ${{ $selected_java_window.title }}    bring_foreground=${FALSE}
                Set Global Variable    ${JAVA_WINDOW_SELECTED}    ${TRUE}
                Set Global Variable    ${SELECTED_WINDOW_NAME}    ${{ $selected_java_window.title }}
            END
        END
    END

Generate Element List Output
    [Arguments]    ${thelist}
    ${output}=    Set Variable    ${EMPTY}
    FOR    ${index}    ${entry}    IN ENUMERATE    @{thelist}
        ${output}=    Set Variable    ${output}${index}: ${entry}\n\n
    END
    RETURN    ${output}

Load Element Tree
    [Arguments]    ${result}
    Select Java Window    ${result}
    Set Global Variable    ${SELECTED_WINDOW_NAME}    ${result}[selected_java_window]
    Application Refresh
    Set Global Variable    ${ELEMENT_TREE_LOADED}    ${True}
    Display Main Menu
    Refresh Dialog

Inspect Tree
    [Arguments]    ${result}
    Select Java Window    ${result}
    ${lib}=    Get Library Instance    CustomAssistant    # RPA.Assistant
    Log To Console    ${{ $lib._client.results }}
    IF    "locator" in $lib._client.results.keys()
        ${visible}=    Set Variable    ${{ bool($lib._client.results['only_visible']) }}
        ${locator}=    Set Variable    ${{ $lib._client.results['locator'] }}
        Set Global Variable    ${INSPECT_ONLY_VISIBLE}    ${visible}
        Set Global Variable    ${INSPECT_LOCATOR}    ${locator}
        ${elements}=    Java.Get Elements    ${locator}    java_elements=True
        @{result}=    Create List
        IF    ${visible}
            FOR    ${item}    IN    @{elements}
                IF    ${item.x} > 0    Append To List    ${result}    ${item}
            END
            Set Global Variable    ${FOUND_ELEMENTS}    ${result}
        ELSE
            Set Global Variable    ${FOUND_ELEMENTS}    ${elements}
        END
        Set Global Variable    ${RESULT_ELEMENT_TYPE}    "ELEMENTS"
    END
    Display Main Menu
    Refresh Dialog

List Element Roles
    [Arguments]    ${result}
    Set Global Variable    ${SELECTED_WINDOW_NAME}    ${result}[selected_java_window]
    Select Window By Title    ${SELECTED_WINDOW_NAME}    bring_foreground=${FALSE}
    Application Refresh
    ${lib}=    Get Library Instance    Java
    # TODO. ITERATE CONTEXT TREE to count roles etc
    @{roles}=    Create List
    FOR    ${index}    ${item}    IN ENUMERATE    @{lib.context_info_tree}
        Append To List    ${roles}    ${item.context_info.role}
    END
    ${roles}=    Remove Duplicates    ${roles}
    Set Global Variable    ${FOUND_ROLES}    ${roles}
    Set Global Variable    ${RESULT_ELEMENT_TYPE}    "ROLES"
    Display Main Menu
    Refresh Dialog

Traversing Element Tree
    Select Window By Title    ${SELECTED_WINDOW_NAME}    bring_foreground=${FALSE}
    # ${tree}=    Print Element Tree
    ${lib}=    Get Library Instance    Java
    # TODO. ITERATE CONTEXT TREE to count roles etc
    FOR    ${index}    ${item}    IN ENUMERATE    @{lib.context_info_tree}
        ${tabs}=    Set Variable    ${SPACE*${item.ancestry}}
        Log To Console    ${tabs} [${item.ancestry}] ${item.context_info.role} ${item.context_info.name}
        # ...    ${tabs} [${item.ancestry}-${item.context_info.indexInParent}] ${item.context_info.role} ${item.context_info.name}
    END

Back To Main Menu
    [Documentation]
    ...    This keyword handles the results of the form whenever the "Back" button
    ...    is used, and then we return to the main menu
    [Arguments]    ${results}={}

    # Handle the dialog results via the passed 'results' -variable
    # Logging the user outputs directly is bad practice as you can easily expose things that should not be exposed
    IF    'password' in ${results}    Log To Console    Do not log user inputs!
    IF    'file' in ${results}
        Log To Console    Selected files: ${results}[file]
        Set Global Variable    ${SELECTED_FILE}    ${results}[file]
    END

    Display Main Menu
    Refresh Dialog

Write locator tree to file
    [Arguments]    ${result}
    Set Global Variable    ${SELECTED_WINDOW_NAME}    ${result}[selected_java_window]
    Select Window By Title    ${SELECTED_WINDOW_NAME}    bring_foreground=${FALSE}
    Application Refresh
    ${tree}=    Print Locator Tree
    Create file    ${LOCATOR_TREE_FILE}    content=${tree}    overwrite=${True}
    ${tree}=    Print Element Tree
    Create file    ${ELEMENT_TREE_FILE}    content=${tree}    overwrite=${True}

List locator tree
    [Documentation]    Action shows all text, image and icon components
    [Arguments]    ${result}
    Set Global Variable    ${SELECTED_WINDOW_NAME}    ${result}[selected_java_window]
    Select Window By Title    ${SELECTED_WINDOW_NAME}    bring_foreground=${FALSE}
    Application Refresh
    # Clear Dialog

    ${lib}=    Get Library Instance    Java
    ${tree}=    Print Locator Tree
    ${raw_tree}=    Get Locator Tree
    # ${tree}=    Evaluate    $tree.replace("| ", "--")    # "${SPACE}${SPACE}")
    # Add DataTable Container    ${lib}
    Set Global Variable    ${FOUND_LOCATORS}    ${tree}
    Set Global Variable    ${FOUND_LOCATORS_RAW}    ${raw_tree}
    Set Global Variable    ${RESULT_ELEMENT_TYPE}    "LOCATORS"
    # Add Text    Found locators:
    # Add Text Input    treeoutput    default=${tree}    minimum_rows=5
    # Add Next Ui Button    Back    Back To Main Menu
    Display Main Menu
    Refresh Dialog

Show Roles Results
    Log List    ${FOUND_ROLES}    level=WARN
    ${formatted}=    Evaluate    "\\nrole:".join(${FOUND_ROLES})
    ${formatted}=    Set Variable    role:${formatted}

    Add Heading    Results:    Small
    Add Text    Found Roles:
    Add Text Input    output    default=${formatted}    minimum_rows=5

Show Element Results
    ${len}=    Get Length    ${FOUND_ELEMENTS}
    ${out}=    Generate Element List Output    ${FOUND_ELEMENTS}
    Log List    ${FOUND_ELEMENTS}    level=WARN

    Add Heading    Results:    Small
    Add Text    Elements Found: ${len}
    Add Text Input    output    default=${out}    minimum_rows=20

Show Locator Results
    [Arguments]    ${find_locator}=${NONE}
    Add Heading    Results:    Small
    Add Text    Found Locators:
    Open Row
    Add Text Input    find    label=Text search    default=${FIND_STRING}    minimum_rows=1    maximum_rows=1
    Add Next UI Button    Search    Find locator
    Close Row
    # Add Text Input    output    default=${FOUND_LOCATORS}    minimum_rows=20
    Set Global Variable    ${FIND_STRING}    ${NONE}
    Add DataTable Container    ${FOUND_LOCATORS_RAW}    ${find_locator}

Find Locator
    [Arguments]    ${result}
    Set Global Variable    ${RESULT_ELEMENT_TYPE}    "FIND"
    Set Global Variable    ${FIND_STRING}    ${result}[find]
    Display Main Menu
    Refresh Dialog
