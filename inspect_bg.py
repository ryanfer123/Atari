import json

def find_bg():
    try:
        with open('assets/lotties/background.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        print(f"Top level bg: {data.get('bg')}")
        
        layers = data.get('layers', [])
        for i, layer in enumerate(layers):
            name = layer.get('nm', 'Unnamed')
            # Check shapes inside the layer for rectangles or fills
            shapes = layer.get('shapes', [])
            for shape in shapes:
                if shape.get('ty') == 'rc':
                    print(f"Layer {i} has a rectangle!")
                if shape.get('ty') == 'gr': # Group
                    for item in shape.get('it', []):
                        if item.get('ty') == 'rc':
                            s = item.get('s', {}).get('k', [])
                            print(f"Layer {i} group has a rectangle of size {s}")
                        if item.get('ty') == 'fl':
                            c = item.get('c', {}).get('k', [])
                            print(f"Layer {i} group has a fill of color {c}")
    except Exception as e:
        print(e)

find_bg()
