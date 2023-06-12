from RPA.JavaAccessBridge import JavaAccessBridge
import subprocess
import time

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


def main():
    java.select_window("Chat Frame")
    elements = java.get_elements("role:push button")
    print(elements)
    java.close_java_window()


if __name__ == "__main__":
    start_application()
    main()
