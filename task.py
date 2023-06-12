from RPA.JavaAccessBridge import JavaAccessBridge
import subprocess
import time
import mimetypes

java = JavaAccessBridge(
    ignore_callbacks=False,
    access_bridge_path="C:\\Apps\\javasdk19\\bin\\windowsaccessbridge-64.dll",
)


def start_application(title: str = ""):
    subprocess.Popen(f"java -jar BasicSwing.jar {title}", shell=True, cwd=".")


def close_application(title):
    java.select_window(title)
    java.select_menu("FILE", "Exit")
    java.select_window("Exit")
    java.click_element("name:Exit ok")


def iterating_context_tree():
    for item in java.context_info_tree:
        print(f"\nname: {item.context_info.name}")
        print(f"role: {item.context_info.role}")
        print(f"x: {item.context_info.x}")
        print(f"y: {item.context_info.y}")
        print(f"width: {item.context_info.width}")
        print(f"height: {item.context_info.height}")
        print(f"states: {item.context_info.states}")
        print(f"ancestry: {item.ancestry}")


def main():
    java.select_window_by_title("Chat Frame")
    iterating_context_tree()
    elements = java.get_elements("role:push button")
    print(elements)
    java.print_element_tree("basicswing_elementtree.txt")
    java.close_java_window()


if __name__ == "__main__":
    start_application()
    main()
