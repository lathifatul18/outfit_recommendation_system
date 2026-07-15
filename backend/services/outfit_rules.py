OUTFIT_RULES = {
    # Upperwear rules
    "tshirt": {
        "bottomwear": ["pants", "shorts"],
        "footwear": ["sneakers", "shoes"],
        "accessories": ["bag", "hat"]
    },
    "shirt": {
        "bottomwear": ["pants"],
        "footwear": ["shoes"],
        "accessories": ["bag"]
    },
    "jacket": {
        "bottomwear": ["pants"],
        "footwear": ["sneakers", "shoes"],
        "accessories": ["bag"]
    },

    # One-piece rules
    "dress": {
        "footwear": ["heels", "flats"],
        "accessories": ["bag"]
    },

    # Bottomwear rules
    "pants": {
        "upperwear": ["tshirt", "shirt", "jacket"],
        "footwear": ["sneakers", "shoes"],
        "accessories": ["bag"]
    },
    "shorts": {
        "upperwear": ["tshirt", "shirt"],
        "footwear": ["sneakers"],
        "accessories": ["bag", "hat"]
    },
    "skirt": {
        "upperwear": ["tshirt", "shirt"],
        "footwear": ["flats", "heels"],
        "accessories": ["bag"]
    },

    # Footwear rules
    "flats": {
        "upperwear": ["tshirt", "shirt"],
        "bottomwear": ["skirt", "pants"],
        "accessories": ["bag"]
    },
    "heels": {
        "upperwear": ["shirt"],
        "bottomwear": ["skirt"],
        "accessories": ["bag"]
    },
    "shoes": {
        "upperwear": ["shirt", "jacket"],
        "bottomwear": ["pants"],
        "accessories": ["bag"]
    },
    "sneakers": {
        "upperwear": ["tshirt", "jacket"],
        "bottomwear": ["pants", "shorts"],
        "accessories": ["bag"]
    },

    # Accessories rules
    "bag": {
        "upperwear": ["tshirt", "shirt"],
        "bottomwear": ["pants", "shorts", "skirt"],
        "footwear": ["sneakers", "shoes", "flats", "heels"]
    },
    "hat": {
        "upperwear": ["tshirt"],
        "bottomwear": ["shorts"],
        "footwear": ["sneakers"],
        "accessories": ["bag"]
    }
}