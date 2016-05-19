#ifndef TREEBUILDING_H
#define TREEBUILDING_H

enum
{
  AM_TREEBUILDING = 33,
REBUILD_PERIOD = 5*1024,// Exact 5 seconds because in Nesc 1024 ticks==1second 
};

typedef nx_struct TreeBuilding
{
  nx_uint16_t seq_no;
  nx_uint16_t metric;
} TreeBuilding;

#endif
