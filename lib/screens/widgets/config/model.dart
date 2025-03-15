import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/modules/controls/adaptive_bottom_sheet.dart';
import 'model_config_sheet.dart';
import 'package:magicai/services/system_manager.dart';

class ModelListTest extends StatefulWidget {
  const ModelListTest({super.key});

  @override
  State<ModelListTest> createState() => _ModelListTestState();
}

class _ModelListTestState extends State<ModelListTest> {
  final List<ModelConfig> _chatItems = SystemConfig.instance.modelConfig;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final int _page = 0;
  final bool _isLoading = true;
  final bool _hasMore = true;
  int _selectedIndex = SystemManager.instance.currentModelIndex();

  Future<void> _loadMoreItems() async {
    // if (!_hasMore || _isLoading) return;

    // setState(() => _isLoading = true);
    // await Future.delayed(const Duration(seconds: 1));
    // if (!mounted) return;

    // final newItems = List.generate(10, (i) => 'Page ${_page + 1} Item $i');
    // final startIndex = _chatItems.length;

    // setState(() {
    //   _page++;
    //   _hasMore = _page < 3;
    //   _chatItems.addAll(newItems);

    //   for (var i = 0; i < newItems.length; i++) {
    //     _listKey.currentState?.insertItem(
    //       startIndex + i,
    //       duration: const Duration(milliseconds: 300),
    //     );
    //   }
    //   _isLoading = false;
    // });
  }

  void _addItem() {
    showConfigBottomSheet(
      context,
      ModelConfigSheet(
        onModelSave: (config) {
          config.index = _chatItems.length;
          SystemConfig.instance.addModelInst(config);
          SystemManager.instance.saveSystemConfig();
          final newIndex = _chatItems.length;

          setState(() {
            _listKey.currentState?.insertItem(
              newIndex - 1,
              duration: const Duration(milliseconds: 150),
            );
            if (newIndex == 1) {
              _handleItemSelected(newIndex - 1);
              // Navigator.pop(context);
            }

            // _listKey.currentState?.insertItem(
            // newIndex,
            // duration: const Duration(milliseconds: 300),
            // );
            // systemConfig?.addModelInst(config);
          });
        },
      ),
    );
    // final newIndex = _chatItems.length;
    // _chatItems.insert(newIndex, Mo);
  }

  void _modifiedItem(int index) {
    showConfigBottomSheet(
      context,
      ModelConfigSheet(
        onModelSave: (config) {
          setState(() {
            SystemConfig.instance.modelConfig[index] = config;
          });
          SystemManager.instance.saveSystemConfig();
        },
        modelConfig: SystemConfig.instance.modelConfig[index],
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除此聊天记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performRemove(index);
                },
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  void _performRemove(int index) {
    if (index >= _chatItems.length) return;

    final removedItem = _chatItems.removeAt(index);

    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = -1;
      } else if (_selectedIndex > index) {
        _selectedIndex--;
      }
    });

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovingItem(removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 "$removedItem"'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            _chatItems.insert(index, removedItem);
            if (_selectedIndex >= index) _selectedIndex++;
            _listKey.currentState?.insertItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildRemovingItem(ModelConfig item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          title: Text(item.modelName),
          subtitle: const Text('Last message...'),
        ),
      ),
    );
  }

  void _handleItemSelected(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? -1 : index;
      SystemManager.instance.doSelectModel(index);
      Navigator.pop(context);
    });
  }

  Widget _buildModelConfigList() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ModelListView(
            listKey: _listKey,
            items: _chatItems,
            hasMore: _hasMore,
            selectedIndex: _selectedIndex,
            onItemRemoved: _removeItem,
            onLoadMore: _loadMoreItems,
            onItemModified: _modifiedItem,
            onItemSelected: _handleItemSelected,
            getTitleName: (list, index) => _chatItems[index].modelName,
            getDescription: (list, index) => 'OK了 ${list[index]}',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;
    // final isDesktop = size.width > 600;
    return Scaffold(
      // appBar:
      // // isDesktop
      // // ? null
      // // :
      // AppBar(
      //   title: const Text('智能体配置界面'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.close),
      //       onPressed: () {
      //         Navigator.pop(context);
      //       },
      //     ),
      //   ],
      // ),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("模型参数配置"),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
      ),
      backgroundColor: Colors.transparent,
      body: _buildModelConfigList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ModelListView extends StatefulWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List items;
  final bool hasMore;
  final int selectedIndex;
  final Function(int) onItemRemoved;
  final Function(int) onItemModified;
  final Future<void> Function() onLoadMore;
  final Function(int) onItemSelected;
  final String Function(List<dynamic>, int) getTitleName;
  final String Function(List<dynamic>, int) getDescription;

  const ModelListView({
    super.key,
    required this.listKey,
    required this.items,
    required this.hasMore,
    required this.selectedIndex,
    required this.onItemModified,
    required this.onItemRemoved,
    required this.onLoadMore,
    required this.onItemSelected,
    required this.getTitleName,
    required this.getDescription,
  });

  @override
  State<ModelListView> createState() => _ModelListViewState();
}

class _ModelListViewState extends State<ModelListView> {
  final ScrollController _scrollController = ScrollController();
  final _hoverNotifier = ValueNotifier<int>(-1);
  bool _isLoading = false;

  static const _itemPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const _itemBorderRadius = BorderRadius.all(Radius.circular(8));
  static const _animationDuration = Duration(milliseconds: 200);

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hoverNotifier.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        widget.hasMore) {
      setState(() => _isLoading = true);
      widget
          .onLoadMore()
          .then((_) {
            if (mounted) setState(() => _isLoading = false);
          })
          .catchError((_) {
            if (mounted) setState(() => _isLoading = false);
          });
    }
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    final isSelected = widget.selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: _hoverNotifier,
      builder: (context, hoverIndex, child) {
        final isHovered = hoverIndex == index;
        return _isDesktop
            ? _buildDesktopItem(
              index,
              isSelected,
              isHovered,
              colorScheme,
              animation,
            )
            : _buildMobileItem(index, isSelected, colorScheme, animation);
      },
    );
  }

  Widget _buildDesktopItem(
    int index,
    bool isSelected,
    bool isHovered,
    ColorScheme colorScheme,
    Animation<double> animation,
  ) {
    return MouseRegion(
      onEnter: (_) => _hoverNotifier.value = index,
      onExit: (_) => _hoverNotifier.value = -1,
      child: GestureDetector(
        onTap: () {
          widget.onItemSelected(index);
        },
        child: AnimatedContainer(
          duration: _animationDuration,
          decoration: BoxDecoration(
            color: _getItemBackgroundColor(isSelected, isHovered, colorScheme),
            borderRadius: _itemBorderRadius,
            border:
                isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
          ),
          margin: _itemPadding,
          child: _buildItemContent(index, isSelected, colorScheme, animation),
        ),
      ),
    );
  }

  Widget _buildMobileItem(
    int index,
    bool isSelected,
    ColorScheme colorScheme,
    Animation<double> animation,
  ) {
    return Dismissible(
      key: Key(widget.getTitleName(widget.items, index)),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除此聊天记录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('删除'),
                  ),
                ],
              ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => widget.onItemRemoved(index),
      child: AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color: _getItemBackgroundColor(isSelected, false, colorScheme),
          borderRadius: _itemBorderRadius,
        ),
        margin: _itemPadding,
        child: _buildItemContent(index, isSelected, colorScheme, animation),
      ),
    );
  }

  Color? _getItemBackgroundColor(
    bool isSelected,
    bool isHovered,
    ColorScheme colorScheme,
  ) {
    if (isSelected) return colorScheme.primaryContainer;
    if (isHovered) return colorScheme.primary.withOpacity(0.1);
    return null;
  }

  Widget _buildItemRightButton(
    int index,
    bool isSelected,
    ColorScheme colorScheme,
  ) {
    return AnimatedSwitcher(
      duration: _animationDuration,
      child:
          _hoverNotifier.value == index || isSelected
              ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.error),
                    onPressed: () => widget.onItemRemoved(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.info, color: colorScheme.primary),
                    onPressed: () => widget.onItemModified(index),
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildItemContent(
    int index,
    bool isSelected,
    ColorScheme colorScheme,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(
          widget.getTitleName(widget.items, index),
          style: TextStyle(
            color:
                isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          widget.getDescription(widget.items, index),
          style: TextStyle(
            color:
                isSelected
                    ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing:
            _isDesktop
                ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child:
                      _hoverNotifier.value == index
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => widget.onItemModified(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => widget.onItemRemoved(index),
                              ),
                            ],
                          )
                          : const SizedBox.shrink(),
                )
                : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: () {
          widget.onItemSelected(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: widget.listKey,
      controller: _scrollController,
      initialItemCount: widget.items.length,
      itemBuilder: (context, index, animation) {
        return _buildListItem(index);
        // return index >= widget.items.length
        //     ? _buildLoadingIndicator()
        //     : _buildItem(context, index, animation);
      },
    );
    // return Scaffold(
    //   appBar: AppBar(title: const Text('Edit List')),
    //   body: ListView.builder(
    //     itemCount: widget.items.length,
    //     itemBuilder: (context, index) {
    //       return _buildListItem(index);
    //     },
    //   ),
    // );
  }

  Widget _buildListItem(int index) {
    final isSelected = widget.selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isDesktop) {
      return MouseRegion(
        onEnter: (_) => _hoverNotifier.value = index,
        onExit: (_) => _hoverNotifier.value = -1,
        child: GestureDetector(
          onTap: () {
            widget.onItemSelected(index);
          },

          child: _DesktopListItem(
            title: widget.getTitleName(widget.items, index),
            subTitle: widget.getDescription(widget.items, index),
            onEdit: () => widget.onItemModified(index),
            onDelete: () => widget.onItemRemoved(index),
            onItemSelect: () => widget.onItemSelected(index),
            isSelected: isSelected,
            colorScheme: colorScheme,
          ),
        ),
      );
    } else {
      return AnimatedContainer(
        duration: _animationDuration,
        decoration: BoxDecoration(
          color: _getItemBackgroundColor(isSelected, false, colorScheme),
          borderRadius: _itemBorderRadius,
          border:
              isSelected
                  ? Border.all(color: colorScheme.primary, width: 2)
                  : null,
        ),
        margin: _itemPadding,
        child: _MobileListItem(
          title: widget.getTitleName(widget.items, index),
          subTitle: widget.getDescription(widget.items, index),
          onEdit: () => widget.onItemModified(index),
          onDelete: () => widget.onItemRemoved(index),
          onItemSelect: () => widget.onItemSelected(index),
          isSelected: isSelected,
          colorScheme: colorScheme,
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child:
            widget.hasMore
                ? const CircularProgressIndicator()
                : Text(
                  '没有更多数据',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
      ),
    );
  }
}

class _DesktopListItem extends StatefulWidget {
  final String title;
  final String subTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onItemSelect;
  late bool isSelected = false;
  late ColorScheme colorScheme;

  _DesktopListItem({
    required this.title,
    required this.subTitle,
    required this.onEdit,
    required this.onDelete,
    required this.onItemSelect,
    this.isSelected = false,
    required this.colorScheme,
  });

  @override
  State<_DesktopListItem> createState() => _DesktopListItemState();
}

class _DesktopListItemState extends State<_DesktopListItem> {
  bool _isHovered = false;
  static const _itemPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const _itemBorderRadius = BorderRadius.all(Radius.circular(8));
  static const _animationDuration = Duration(milliseconds: 200);

  Color? _getItemBackgroundColor(
    bool isSelected,
    bool isHovered,
    ColorScheme colorScheme,
  ) {
    if (isSelected) return colorScheme.primaryContainer;
    if (isHovered) return colorScheme.primary.withOpacity(0.1);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onItemSelect();
        },
        child: AnimatedContainer(
          duration: _animationDuration,
          decoration: BoxDecoration(
            color: _getItemBackgroundColor(
              widget.isSelected,
              _isHovered,
              widget.colorScheme,
            ),
            borderRadius: _itemBorderRadius,
            border:
                widget.isSelected
                    ? Border.all(color: widget.colorScheme.primary, width: 2)
                    : null,
          ),
          margin: _itemPadding,
          child: ListTile(
            title: Text(
              widget.title,
              style: TextStyle(
                color:
                    widget.isSelected
                        ? widget.colorScheme.onPrimaryContainer
                        : widget.colorScheme.onSurface,
              ),
            ),
            trailing: AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileListItem extends StatelessWidget {
  final String title;
  final String subTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onItemSelect;
  late bool isSelected = false;
  late ColorScheme colorScheme;

  _MobileListItem({
    required this.title,
    required this.subTitle,
    required this.onEdit,
    required this.onDelete,
    required this.onItemSelect,
    this.isSelected = false,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(title),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete();
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return null;
      },
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color:
                isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          itemBuilder:
              (context) => [
                PopupMenuItem(onTap: onEdit, child: const Text('Edit')),
                PopupMenuItem(onTap: onDelete, child: const Text('Delete')),
              ],
        ),
        onTap: () {
          onItemSelect();
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Edit'),
                        onTap: () {
                          Navigator.pop(context);
                          onEdit();
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: const Text('Delete'),
                        onTap: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }
}
