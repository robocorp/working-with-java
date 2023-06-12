*** Settings ***
Library     RPA.JavaAccessBridge
...             ignore_callbacks=True
...             access_bridge_path=C:\\Apps\\javasdk19\\bin\\windowsaccessbridge-64.dll
Library     Process
Library     Collections
Library     OperatingSystem
Library     RPA.Assistant
Library     RPA.Windows


*** Variables ***
${SELECTED_FILE}            ${NONE}
@{FOUND_ELEMENTS}           @{EMPTY}
&{FOUND_ROLES}              &{EMPTY}
${JAVA_WINDOW_SELECTED}     ${FALSE}
${INSPECT_ONLY_VISIBLE}     ${TRUE}
${INSPECT_LOCATOR}          Insert locator..


*** Tasks ***
Assistant Main
    [Documentation]
    ...    The Main task running the Assistant
    ...    Configure your window behaviour here
    Display Main Menu
    ${result}=    RPA.Assistant.Run Dialog
    ...    title=Assistant for Java
    ...    on_top=True
    ...    height=600
    ...    timeout=3600

Using Old Java
    # lets foreground
    Select Window By Title    Chat Frame    # bring_foreground=False
    # ${javas}=    List Java Windows
    # FOR    ${j}    IN    @{javas}
    #    Log To Console    ${j}
    #    Select Window By Pid    ${j.pid}
    # END

    # Foreground Window    Chat Frame


*** Keywords ***
Display Main Menu
    [Documentation]
    ...    Main UI of the bot. We use the "Back To Main Menu" keyword
    ...    with buttons to make other views return here.
    Clear Dialog
    Add Heading    Java Assistant
    # IF    ${SELECTED_FILE}
    #    Add Text    Selected file: ${SELECTED_FILE}
    # ELSE
    #    Add Text    No file selected
    # END
    ${javas}=    List Java Windows
    Log List    ${javas}    level=WARN
    IF    len($javas)==1
        Add text    Target: ${{ $javas[0].title }}
        IF    not ${JAVA_WINDOW_SELECTED}
            Select Window By Pid    ${{ $javas[0].pid }}
            Set Global Variable    ${JAVA_WINDOW_SELECTED}    ${TRUE}
        END
    END

    # Add Button    Inspect Element Tree from file    Show Input Components
    Add Text Input    locator    placeholder=${INSPECT_LOCATOR}    default=${INSPECT_LOCATOR}
    Add Checkbox    only_visible    Only visible    ${INSPECT_ONLY_VISIBLE}
    Add Button    Inspect    Inspect Tree
    Add Button    Refresh    Application Refresh
    Add Button    List element roles    List Element Roles
    Add Button    Check element tree    Show Static Components
    # Add File Input    file    Select file with element tree output    source=${CURDIR}    file_type=txt
    # Add Text    Get Started:
    # Add Button    Simple Example    Show Example View
    IF    ${FOUND_ELEMENTS}
        ${len}=    Get Length    ${FOUND_ELEMENTS}
        ${out}=    Generate list output    ${FOUND_ELEMENTS}
        Log List    ${FOUND_ELEMENTS}    level=WARN
        Add Text    Result count: ${len}
        Add Text    ${out}    size=Small
    END
    IF    ${FOUND_ROLES}
        Log List    ${FOUND_ROLES}    level=WARN
        Add Text    ${FOUND_ROLES}    size=Small
    END
    Add Submit Buttons    buttons=Close    default=Close

Generate List Output
    [Arguments]    ${thelist}
    ${output}=    Set Variable    ${EMPTY}
    FOR    ${index}    ${entry}    IN ENUMERATE    @{thelist}
        ${output}=    Set Variable    ${output}${index}: ${entry}\n
    END
    RETURN    ${output}

Inspect Tree
    ${lib}=    Get Library Instance    RPA.Assistant
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
    Set Global Variable    ${FOUND_ROLES}    ${roles}
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

Show Static Components
    [Documentation]    Action shows all text, image and icon components

    Clear Dialog
    ${tree}=    Print Element Tree
    Add Text    ${tree}

    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Show Input Components
    [Documentation]    Action shows all input components

    Clear Dialog
    Add Heading    Input handling

    Add Text Input    text_input    This is a text input
    Add Password Input    password    This is a secret

    Add Drop-down
    ...    name=user_type
    ...    options=Admin,Maintainer,Operator
    ...    default=Admin
    ...    label=Drop-down

    Add Radio Buttons
    ...    name=radio_button
    ...    options=Option A,Option B, Option C
    ...    default=Option A
    ...    label=Radio Buttons

    Add Slider
    ...    name=percentage
    ...    slider_min=0
    ...    slider_max=100
    ...    thumb_text={value}%
    ...    steps=100

    Add Checkbox    checkbox    This is a checkbox    True
    Add Hidden Input    hidden_field    This is hidden

    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Show File Components
    [Documentation]    Action shows all file input components

    Clear Dialog
    Add Heading    Select file

    # Add File    ${CURDIR}${/}elementtree.txt    label=Current
    Add File Input    file    Select file with element tree output    source=${CURDIR}    file_type=txt

    Add Next Ui Button    Back    Back To Main Menu

    Refresh Dialog

Show Example View
    [Documentation]
    ...    A clean example view to get started
    ...    Contains a single action that demonstrates error handling

    Clear Dialog    # We clear the current view when starting to create another view
    Add Heading    Example with error handling
    Add Text    The action below causes an error, but we only log it and continue.
    # A button that calls a keyword that fails
    Add Button    Get Image - Error handling    Get Data

    # We use "Add Next Ui Button" keyword to generate a back button, that will pass the ${results}
    # of the dialog to the keyword "Back To Main Menu"
    Add Next Ui Button    Back    Back To Main Menu
    Refresh Dialog

Get Data
    [Documentation]    Example of exception handling

    TRY
        # This action fails to demostrate the exception handling
        Get File    notfound.png
    EXCEPT    message
        # Handle the exceptions here and perform the actions you want
        # You can create an error view and jump to there, etc.
        Log    Handling Get Data error case
    FINALLY
        # In this case we just want to continue running the assistant, so we return to the main view
        Back To Main Menu
    END
