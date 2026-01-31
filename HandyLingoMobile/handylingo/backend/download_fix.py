import sign_language_translator as slt

try:
    print("Trying to download ONLY the essential English dictionary...")
    # This specifically targets the English dictionary assets
    slt.utils.Assets.download(r"text/english-dictionary.json")
    print("Success!")
except Exception as e:
    print(f"Failed again. Error: {e}")

    print("\n--- Manual Asset Check ---")
    import os

    root = slt.utils.Assets.ROOT_DIR
    print(f"Library is looking for assets in: {os.path.abspath(root)}")