from RPA.Assistant import Assistant
from flet_core.control_event import ControlEvent

from flet import (
    DataTable,
    DataCell,
    DataColumn,
    ElevatedButton,
    Text,
    DataRow,
)

from robot.api.deco import keyword, library
from robot.libraries.BuiltIn import BuiltIn
from typing import Union, Callable


@library(scope="GLOBAL", doc_format="REST", auto_keywords=False)
class CustomAssistant(Assistant):
    def __init__(self) -> None:
        super().__init__()

    @keyword
    def add_datatable_container(self, java_lib) -> None:
        def method_for_table_item_update(e):
            BuiltIn().log_to_console(dir(e))
            BuiltIn().log_to_console(e)
            BuiltIn().log_to_console(dir(e.target))
            self._client.flet_update()

        data_rows = []
        for item in java_lib.context_info_tree:
            coords = (
                f"x={item.context_info.x} y={item.context_info.y}"
                if item.context_info.x >= 0
                else "NOT VISIBLE"
            )
            data_rows.append(
                DataRow(
                    [
                        DataCell(Text(item.ancestry, size=10)),
                        DataCell(Text(item.context_info.role, size=10)),
                        DataCell(Text(item.context_info.name, size=10)),
                        DataCell(Text(coords, size=10)),
                    ],
                ),
            )

        dt = DataTable(
            # width=700,
            # bgcolor="white",
            border_radius=10,
            sort_column_index=0,
            sort_ascending=True,
            heading_row_color="black",
            heading_row_height=100,
            data_row_color={"hovered": "black"},
            show_checkbox_column=False,
            divider_thickness=0,
            # column_spacing=200,
            columns=[
                DataColumn(
                    Text("Element level"),
                ),
                DataColumn(
                    Text("Element role"),
                ),
                DataColumn(
                    Text("Element name"),
                ),
                DataColumn(
                    Text("Coordinates"),
                ),
            ],
            rows=data_rows,
        )

        self._client.add_element(dt)

    @keyword(tags=["dialog"])
    def add_next_ui_button_with_tooltip(
        self, label: str, function: Union[Callable, str], tooltip: str = None
    ):
        """Create a button that leads to the next UI page, calling the passed
        keyword or function, and passing current form results as first positional
        argument to it.

        :param label: Text for the button
        :param function: Python function or Robot Keyword name, that will take form
            results as its first argument

        Example:

        .. code-block:: robotframework

            *** Keywords ***
            Retrieve User Data
                # Retrieves advanced data that needs to be displayed

            Main Form
                Add Heading  Username input
                Add Text Input  name=username_1  placeholder=username
                Add Next Ui Button        Show customer details  Customer Details

            Customer Details
                [Arguments]  ${form}
                ${user_data}=  Retrieve User Data  ${form}[username_1]
                Add Heading  Retrieved Data
                Add Text  ${user_data}[phone_number]
                Add Text  ${user_data}[address]
        """

        def on_click(_: ControlEvent):
            self._callbacks.queue_fn_or_kw(function, self._get_results())
            self._client.page.set_clipboard(tooltip)

        button = ElevatedButton(label, on_click=on_click, tooltip=tooltip)
        self._client.add_element(button)
        self._client.add_to_disablelist(button)
