from RPA.Assistant import Assistant
from RPA.Assistant.types import (
    Icon,
    LayoutError,
    Location,
    Options,
    Result,
    Size,
    VerticalLocation,
    WindowLocation,
)
import logging
from flet import DataTable, DataCell, DataColumn, Text, DataRow
from flet_core.control_event import ControlEvent
from robot.api.deco import keyword, library
from robot.libraries.BuiltIn import BuiltIn


@library(scope="GLOBAL", doc_format="REST", auto_keywords=False)
class CustomAssistant(Assistant):
    def __init__(self) -> None:
        super().__init__()

    @keyword
    def add_datatable_container(self, java_lib) -> None:
        def what_the_hell(e):
            BuiltIn().log_to_console("what the hell")
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
            rows=data_rows
            # rows=[
            #     DataRow(
            #         [DataCell(Text("A")), DataCell(Text("1"))],
            #         selected=True,
            #         on_select_changed=what_the_hell,
            #     ),
            #     DataRow(
            #         [DataCell(Text("B")), DataCell(Text("2"))],
            #         selected=False,
            #         on_select_changed=what_the_hell,
            #     ),
            # ],
        )

        self._client.add_element(dt)
