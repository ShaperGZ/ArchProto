
module ArchComponents
  def ArchComponents.reload()
    # this dictionary contains the actual file path
    $arch_components=Hash.new()
    # this dictionay contains the skp definition witch will be used to create objects on scene
    $arch_skp_definitions=Hash.new()

    # use ArchComponents.get_names(key) to get the name for UI titles
    files=self._get_all_skp_files('generator_components')

    trgs=['htl_rm','core_apt']
    for t in trgs
      $arch_components[t]=[]
    end

    for f in files
      name=f.split('/')[-1]
      p "processing #{name}"
      $arch_skp_definitions[name]= self._load_definition(f)
      for t in trgs
        if name.include? t
          $arch_components[t]<<f;
          break
        end
      end # end for t
    end # end for f
  end

  def ArchComponents._load_definition(path)
    d=Sketchup.active_model.definitions.load(path)
  end

  def ArchComponents.instantiate(componentName,container)
    definition=$arch_skp_definitions[componentName]
    o=container.entities.add_instance(definition,Geom::Transformation.new)
    return o
  end

  def ArchComponents.get_names(key)
    # extract the names for display from the arch component dictionary
    if !$arch_components.key? key
      return
    end
    names=[]
    $arch_components[key].each{|item|
      # you are extracting from xxx/xx/xx/htl_rm_6.0x9.0.skp
      names<<item.split('/')[-1].gsub('.skp','')
    }
    return names
  end

  def ArchComponents._get_all_skp_files(folderName)
    # extract all full path file names from the a given folder
    # sample input: 'generator_components'
    path=ArchProto.get_file_path(folderName+'/')
    skpfiles=Dir.glob(path+'*.skp')
    $all_component_file_names=skpfiles
    return skpfiles
  end
end

ArchComponents.reload()

