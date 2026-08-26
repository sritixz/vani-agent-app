import os
import subprocess
import glob

def find_keytool():
    # Check PATH first
    try:
        res = subprocess.run(["keytool", "-help"], capture_output=True)
        if res.returncode == 0:
            return "keytool"
    except Exception:
        pass

    # Search common Java / Android Studio locations
    search_paths = [
        r"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
        r"C:\Program Files\Android\Android Studio\jre\bin\keytool.exe",
        r"C:\Program Files\Java\*\bin\keytool.exe",
        r"C:\Users\*\AppData\Local\Android\Sdk\*\keytool.exe",
    ]
    for p in search_paths:
        matches = glob.glob(p)
        if matches:
            return matches[0]
    return "keytool"

keytool_cmd = find_keytool()
keystore_path = os.path.abspath("android/app/upload-keystore.jks")

cmd = [
    keytool_cmd,
    "-genkeypair",
    "-v",
    "-keystore", keystore_path,
    "-storetype", "JKS",
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-alias", "upload",
    "-storepass", "vaniagent123",
    "-keypass", "vaniagent123",
    "-dname", "CN=VaniAgent, OU=Dev, O=VaniAgent, L=City, ST=State, C=US"
]

print("Running command:", " ".join(cmd))
res = subprocess.run(cmd, capture_output=True, text=True)
print("Return code:", res.returncode)
print("Stdout:", res.stdout)
print("Stderr:", res.stderr)

# Write key.properties
key_props = """storePassword=vaniagent123
keyPassword=vaniagent123
keyAlias=upload
storeFile=upload-keystore.jks
"""

key_props_path = os.path.abspath("android/key.properties")
with open(key_props_path, "w") as f:
    f.write(key_props)

print("Created key.properties at:", key_props_path)
