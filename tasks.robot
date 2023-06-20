*** Settings ***
Library     RPA.JavaAccessBridge
...             ignore_callbacks=True
Library     Process
Library     Collections
# Task Setup    Task setup actions


*** Variables ***
${window1}      longer window name
${window2}      short name


*** Tasks ***
Iterating RPA.JavaAccessBridge context_info_tree
    ${lib}=    Get Library Instance    RPA.JavaAccessBridge
    Select Window By Title    Oracle Applications
    FOR    ${item}    IN    @{lib.context_info_tree}
        Log To Console    \nname: ${{ $item.context_info.name }}
        Log To Console    role: ${{ $item.context_info.role }}
        Log To Console    x: ${{ $item.context_info.x }}
        Log To Console    y: ${{ $item.context_info.y }}
        Log To Console    width: ${{ $item.context_info.width }}
        Log To Console    height: ${{ $item.context_info.height }}
        Log To Console    states: ${{ $item.context_info.states }}
        Log To Console    ancestry: ${{ $item.ancestry }}
    END

New version stuff
    ${javas}=    List Java Windows
    FOR    ${java}    IN    @{javas}
        Log To Console    ${java}
        Select Window By Pid    ${java.pid}
    END
    ${elements}=    Get Elements    name:Send1
    Log List    ${elements}    level=WARN
    Wait Until Element Exists    name:Send1
    Click Element    name:Send1
    Sleep    2s
    Click Element    name:Send1
    Sleep    2s
    Click Element    name:Clear2
    # Wait Until Element Exists    name:Send2

Debug Task
    # Select Window By Title    Chat Frame
    ${javas}=    List Java Windows
    FOR    ${java}    IN    @{javas}
        Log To Console    ${java}
        Select Window By Pid    ${java.pid}
    END
    ${tree}=    Print Element Tree
    Log    ${tree}    console=True

Access Multiple Javas
    # window1
    Select Window    \\w{6}\\s\\w{6}.*
    Type Text    role:text    To ${window1} window    clear=True

    # window2
    Select Window    ${window2}
    Type Text    role:text    To ${window2} window    clear=True

    # window 1
    Close Basic Swing Application    \\w{6}\\s\\w{6}.*

    # window2
    Select Window    ${window2}
    Type Text    role:text    AFTER: To ${window2} window    clear=True
    Log    Done.

Start BasicSwing Applications
    Start Applications    ${window1}    ${window2}

Test click element
    Click Element    role:push button and name:Send

Test click push button
    Click Push Button    Send
    Click Push Button    Clear

Test print element tree
    ${tree}=    Print Element Tree

Test typing text
    Type Text    role:text    textarea text
    Type Text    role:text    input field text    index=1    clear=${TRUE}
    Sleep    5s
    ${area_text}=    Get Element Text    role:text    0
    ${input_text}=    Get Element Text    role:text    1
    Should Contain    ${area_text}    textarea text
    Should Be Equal As Strings    input field text    ${input_text}

Test get elements
    ${elements}=    Get Elements    role:text
    ${len}=    Get Length    ${elements}
    Should Be Equal As Integers    ${len}    2
    Log Many    ${elements}[0]
    Log Many    ${elements}[1]
    Highlight Element    ${elements}[0]
    Highlight Element    ${elements}[1]
    Sleep    5s

Test Java Elements
    ${elements}=    Get Elements    role:table > role:label
    Log To Console    ${elements}

Test Closing Java Window
    Select Window    Chat Frame
    Sleep    5
    Close Java Window

Test Listing Java Windows
    @{window_list}=    List Java Windows
    FOR    ${window}    IN    @{window_list}
        IF    "${window.title}" == "my java window title"
            Select Window By PID    ${window.pid}
        END
    END
    IF    len($window_list)==1    Select Window By PID    ${window_list[0].pid}


*** Keywords ***
Exit Demo Application
    Select Window    Chat Frame
    Select Menu    FILE    Exit
    Select Window    Exit
    Click Push Button    Exit ok

Clear chat frame
    Click Element    role:push button and name:Clear

Task setup actions
    Select Window By Title    Chat Frame
    Clear chat frame

Start Applications
    [Arguments]    @{windowtitles}
    FOR    ${title}    IN    @{windowtitles}
        Start Process    java -jar BasicSwing.jar "${title}"
        ...    shell=${TRUE}
        ...    cwd=${CURDIR}
    END

Close Basic Swing Application
    [Arguments]    ${windowtitle}
    Select Window    ${windowtitle}
    Select Menu    FILE    Exit
    Select Window    Exit
    Click Element    name:Exit ok
