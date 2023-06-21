*** Settings ***
Library     RPA.JavaAccessBridge
...             ignore_callbacks=True
Library     Process
Library     Collections
Library     RPA.FileSystem
Library     CustomAssistant.py    # RPA.Assistant
Library     RPA.Windows
Library     String


*** Variables ***
${ELEMENT_TREE_LOADED}      ${FALSE}
${RESULT_ELEMENT_TYPE}      ${NONE}
${SELECTED_FILE}            ${NONE}
@{FOUND_ELEMENTS}           @{EMPTY}
&{FOUND_ROLES}              &{EMPTY}
${JAVA_WINDOW_SELECTED}     ${FALSE}
${INSPECT_ONLY_VISIBLE}     ${TRUE}
#${INSPECT_LOCATOR}          ${NONE}
${INSPECT_LOCATOR}          role:menu and name:FILE
${ELEMENT_TREE_FILE}        %{ROBOT_ARTIFACTS}${/}element-tree.txt


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

    IF   len($javas)==0
        Add Text    No Java applications open.
        Add Submit Buttons    buttons=Close    default=Close
        RETURN
    END
    
    @{titles}=    Evaluate    [obj.title for obj in $javas]
    ${default}=    Evaluate    max(@{titles}, key = len)
    Add Drop-Down  name=selected_java_window  options=@{titles}  default=${default}  label=Select Java window and load element tree

    Add Next UI Button    Load/Refresh Element Tree       Load Element Tree
    
    IF    ${ELEMENT_TREE_LOADED} == ${False}
        Add Submit Buttons    buttons=Close    default=Close
        RETURN
    END

    Add Heading    Actions:   Small

    Add Text    Inspect a locators:
    Add Text Input    locator    default=${INSPECT_LOCATOR}    placeholder=Insert Locator...
    Open Row
    Add Next UI Button    Inspect Locator    Inspect Tree
    Add Checkbox    only_visible    Target only visible elements    ${INSPECT_ONLY_VISIBLE}
    Close Row

    Add Text    List roles and the full tree:
    Open Row
    Add Button    List element roles    List Element Roles
    Add Button    View element tree    List element tree
    Add Button    Write element tree to file    Write element tree to file
    Close Row

    IF    ${RESULT_ELEMENT_TYPE} == "ROLES"
        Show Roles Results
    ELSE IF   ${RESULT_ELEMENT_TYPE} == "ELEMENTS"
        Show Element Results
    ELSE  
        Add Submit Buttons    buttons=Close    default=Close
        RETURN
    END
    Add Submit Buttons    buttons=Close    default=Close


Find Selected Window
    [Arguments]  ${java_windows}  ${selected_title}
    FOR    ${java_window}    IN    @{java_windows}
        Log    ${java_window}
        IF  "${java_window.title}" == "${selected_title}"
            RETURN  ${java_window}
        END
    END

Select Java Window
    [Arguments]  ${result}
    ${javas}=    List Java Windows
    IF  not $result.selected_java_window
        Open Row
        Add icon    Warning    size=24
        Add text    There are no detected Java windows
        Close Row
    ELSE
        ${selected_java_window}=  Find Selected Window  ${javas}  ${result.selected_java_window}
        Add text    Target: ${{ $selected_java_window.title }}
        IF    not ${JAVA_WINDOW_SELECTED}
            Select Window By Title    ${{ $selected_java_window.title }}
            Set Global Variable    ${JAVA_WINDOW_SELECTED}    ${TRUE}
        END
    END

Generate Element List Output
    [Arguments]    ${thelist}
    ${output}=    Set Variable    ${EMPTY}
    FOR    ${index}    ${entry}    IN ENUMERATE    @{thelist}
        ${output}=    Set Variable    ${output}${index}: ${entry}\n
    END
    RETURN    ${output}

Load Element Tree
    [Arguments]  ${result}
    Select Java Window  ${result}
    Application Refresh
    Set Global Variable    ${ELEMENT_TREE_LOADED}    ${True}
    Display Main Menu
    Refresh Dialog

Inspect Tree
    [Arguments]  ${result}
    Select Java Window  ${result}
    ${lib}=    Get Library Instance    CustomAssistant    # RPA.Assistant
    Log To Console    ${{ $lib._client.results }}
    IF    "locator" in $lib._client.results.keys()
        ${visible}=    Set Variable    ${{ bool($lib._client.results['only_visible']) }}
        ${locator}=    Set Variable    ${{ $lib._client.results['locator'] }}
        Set Global Variable    ${INSPECT_ONLY_VISIBLE}    ${visible}
        Set Global Variable    ${INSPECT_LOCATOR}    ${locator}
        ${elements}=    RPA.JavaAccessBridge.Get Elements    ${locator}    java_elements=True
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
    ${lib}=    Get Library Instance    RPA.JavaAccessBridge
    # TODO. ITERATE CONTEXT TREE to count roles etc
    @{roles}=    Create List
    FOR    ${index}    ${item}    IN ENUMERATE    @{lib.context_info_tree}
        Append To List    ${roles}    ${item.context_info.role}
    END
    ${roles}=     Remove Duplicates    ${roles}
    Set Global Variable    ${FOUND_ROLES}    ${roles}
    Set Global Variable    ${RESULT_ELEMENT_TYPE}    "ROLES"
    Display Main Menu
    Refresh Dialog

Traversing Element Tree
    Select Window By Title    Chat Frame
    # ${tree}=    Print Element Tree
    ${lib}=    Get Library Instance    RPA.JavaAccessBridge
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

Write element tree to file
    ${tree}=    Print Element Tree
    Create file    ${ELEMENT_TREE_FILE}    content=${tree}   overwrite=${True}

List element tree
    [Documentation]    Action shows all text, image and icon components
    Clear Dialog

    ${lib}=    Get Library Instance    RPA.JavaAccessBridge
    Add DataTable Container    ${lib}

    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Show Roles Results
    Log List    ${FOUND_ROLES}    level=WARN
    ${formatted}=   Evaluate  "\\nrole:".join(${FOUND_ROLES})
    ${formatted}=   Set Variable  role:${formatted}

    Add Heading    Results:   Small
    Add Text    Found Roles:
    Add Text Input   output   default=${formatted}   minimum_rows=5

Show Element Results
    ${len}=    Get Length    ${FOUND_ELEMENTS}
    ${out}=    Generate Element List Output    ${FOUND_ELEMENTS}
    Log List    ${FOUND_ELEMENTS}    level=WARN

    Add Heading    Results:   Small
    Add Text    Elements Found: ${len}
    Add Text    ${out}    size=Small
