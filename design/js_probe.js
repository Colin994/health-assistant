const p = pixso.getNodeById('16:1');
return {
  name: p.name,
  children: p.children.map(c => ({id: c.id, name: c.name, x: c.x, y: c.y, w: c.width, h: c.height}))
};
