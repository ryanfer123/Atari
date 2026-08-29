import json

def fix_rotation():
    path = 'assets/lotties/background.json'
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    layers = data.get('layers', [])
    for layer in layers:
        r_node = layer.get('ks', {}).get('r', {})
        if r_node and r_node.get('a') == 1:
            keyframes = r_node.get('k', [])
            if len(keyframes) > 0:
                start_angle = keyframes[0].get('s', [0])[0]
                
                # Create two linear keyframes for a seamless 360 rotation over the full 1290 frames
                # We rotate by 360 degrees to match the original speed roughly (360 / 1290 is similar to 146 / 600)
                new_keyframes = [
                    {
                        't': 0,
                        's': [start_angle],
                        'o': {'x': 0.0, 'y': 0.0},
                        'i': {'x': 1.0, 'y': 1.0}
                    },
                    {
                        't': 1290,
                        's': [start_angle + 360]
                    }
                ]
                r_node['k'] = new_keyframes
                
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f)
        
    print("Modified all rotation keyframes to be continuous and linear!")

fix_rotation()
