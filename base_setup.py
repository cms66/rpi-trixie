# First boot - Base setup
# wget https://raw.githubusercontent.com/cms66/rpi-trixie/main/base_setup.py; sudo python ./base_setup.py

# Imports
import  subprocess, sys, os, urllib.request

def main():
    print("Python setup")
    bashfile = "base_setup.sh"
    bashurl = "https://raw.githubusercontent.com/cms66/rpi-trixie/main/" + bashfile
    try:
        urllib.request.urlretrieve(bashurl, bashfile) # Download bash script
        subprocess.run(["sudo", "bash", "./" + bashfile], check=True) # Sudo run bash script
        subprocess.run(["sudo", "rm", "-f", "./" + bashfile], check=True) # Delete bash script
        usropt=input("Base seup done, press p to poweroff or any other key to reboot: ").lower()
        os.remove(__file__) # Delete python script
        if usropt == 'p':
            print ("Poweroff selected")
            subprocess.call(["shutdown", "-s", "now"])
        else:
            print ("Reboot selected")
            subprocess.call(["shutdown", "-r", "now"])
    except Exception as e:
        print("Error:", e)
        sys.exit(1)
    print("Python setup done")
    
if __name__ == "__main__":
    main()
