# Sign language to text mapping
SIGN_LANGUAGE_CLASSES = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S', 19: 'T',
    20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

# 3D Animation mapping (for Hand Talk style animations)
ANIMATION_MAPPING = {
    'A': {'pose': 'hand_closed', 'movement': 'static'},
    'B': {'pose': 'hand_open', 'movement': 'static'},
    'C': {'pose': 'hand_curved', 'movement': 'static'},
    # Add more mappings based on your sign language dataset
}

def get_sign_text(class_index: int) -> str:
    """Get text representation of sign class"""
    return SIGN_LANGUAGE_CLASSES.get(class_index, 'UNKNOWN')

def get_animation_data(text: str) -> dict:
    """Get animation data for text (for 3D sign animation)"""
    animation = ANIMATION_MAPPING.get(text, {
        'pose': 'neutral',
        'movement': 'idle',
        'duration': 1000
    })
    return animation
